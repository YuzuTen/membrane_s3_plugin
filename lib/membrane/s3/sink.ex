defmodule Membrane.S3.Sink do
  @moduledoc """
    Uploads items to an S3 Bucket.
  """
  use Membrane.Sink

  require Membrane.Logger

  def_input_pad(:input, demand_unit: :bytes, caps: :any)

  def_options(
    path: [
      spec: String.t(),
      description: "The path within your S3 bucket where you'd like to store the resource"
    ],
    bucket: [
      spec: String.t(),
      description: "S3 bucket"
    ],
    chunk_size: [
      spec: integer(),
      description: """
              Chunk size in bytes. Determines how many bytes are written to S3 in one request. AWS requires this to be at least 5MB
      """,
      default: 5 * 1_024 * 1_024
    ],
    s3_opts: [
      spec: Keyword.t(),
      description: "S3 options",
      default: []
    ],
    aws_config: [
      spec: Keyword.t(),
      description: "AWS configuration",
      default: []
    ],
    ex_aws: [
      spec: atom(),
      description: "AWS client. Only needed when substituting the default ExAws dependency.",
      default: ExAws
    ]
  )

  def handle_init(%__MODULE__{
        path: path,
        bucket: bucket,
        chunk_size: chunk_size,
        s3_opts: s3_opts,
        aws_config: aws_config,
        ex_aws: ex_aws
      }) do
    {
      :ok,
      %{
        path: path,
        bucket: bucket,
        chunk_size: chunk_size,
        s3_opts: s3_opts,
        aws_config: aws_config,
        ex_aws: ex_aws,
        upload_id: nil,
        upload_index: 1,
        parts: [],
        completed: false,
        current_chunk: [],
        current_chunk_size: 0
      }
    }
  end

  @impl true
  def handle_stopped_to_prepared(
        _ctx,
        %{bucket: bucket, path: path, s3_opts: s3_opts, aws_config: aws_config, ex_aws: ex_aws} =
          state
      ) do
    init_op = ExAws.S3.initiate_multipart_upload(bucket, path, s3_opts)

    case ex_aws.request(init_op, aws_config) do
      {
        :ok,
        %{
          body: %{
            upload_id: upload_id
          }
        }
      } ->
        {:ok, %{state | upload_id: upload_id}}

      {:error, error} ->
        {{:error, error}, state}
    end
  end

  @impl true
  def handle_prepared_to_playing(
        _ctx,
        state
      ) do
    Membrane.Logger.info("Start Playing")

    {{:ok, demand: {:input, state.chunk_size}}, state}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, state) do
    complete_upload(state)
  end

  @impl true
  def handle_end_of_stream(_pad, _ctx, state) do
    complete_upload(state)
  end

  @impl true
  def handle_write(
        :input,
        %Membrane.Buffer{payload: payload},
        _ctx,
        %{
          chunk_size: chunk_size,
          current_chunk: current_chunk,
          current_chunk_size: current_chunk_size
        } = state
      ) do
    current_chunk = [payload | current_chunk]
    current_chunk_size = current_chunk_size + byte_size(payload)

    if current_chunk_size >= chunk_size do
      <<payload::binary-size(chunk_size), rest::binary>> =
        Enum.reverse(current_chunk) |> Enum.join()

      case upload_chunk(payload, %{
             state
             | current_chunk: [rest],
               current_chunk_size: byte_size(rest)
           }) do
        {:ok, parts, count} ->
          {
            {:ok, demand: {:input, state.chunk_size}},
            %{state | upload_index: count, parts: parts}
          }

        {:error, context} ->
          {:error, context, state}
      end
    else
      {
        {:ok, demand: {:input, chunk_size}},
        %{state | current_chunk: current_chunk, current_chunk_size: current_chunk_size}
      }
    end
  end

  defp upload_chunk(
         payload,
         %{
           s3_opts: s3_opts,
           aws_config: aws_config,
           bucket: bucket,
           path: path,
           upload_id: upload_id,
           ex_aws: ex_aws,
           upload_index: upload_index,
           parts: parts
         }
       ) do
    with {:ok, %{headers: headers}} <-
           ExAws.S3.upload_part(
             bucket,
             path,
             upload_id,
             upload_index,
             payload,
             s3_opts
           )
           |> ex_aws.request(aws_config),
         {:ok, etag} <- find_etag(headers) do
      parts = [{upload_index, etag} | parts]
      Membrane.Logger.info("Uploaded part #{etag} to s3")
      {:ok, parts, upload_index + 1}
    else
      error ->
        Membrane.Logger.error("Failed to upload part to S3. #{inspect(error)}")
        error
    end
  end

  defp find_etag(headers) do
    headers
    |> Enum.find_value(
      {:error, :invalid_etag},
      fn {key, value} ->
        if String.equivalent?(String.downcase(key), "etag") do
          {:ok, String.trim(value, "\"")}
        end
      end
    )
  end

  defp complete_upload(%{completed: true} = state), do: {:ok, state}

  defp complete_upload(
         %{
           bucket: bucket,
           path: path,
           upload_id: upload_id,
           ex_aws: ex_aws,
           aws_config: aws_config,
           current_chunk: current_chunk
         } = state
       ) do
    final_chunk = Enum.reverse(current_chunk) |> Enum.join()

    with {:ok, parts, _} <-
           upload_chunk(final_chunk, %{state | current_chunk: [], current_chunk_size: 0}),
         request <-
           ExAws.S3.complete_multipart_upload(bucket, path, upload_id, Enum.reverse(parts)),
         {:ok, response} <- ex_aws.request(request, aws_config) do
      Membrane.Logger.info("Upload complete for #{length(parts)} parts. #{inspect(response)}")
      {:ok, %{state | upload_id: nil, upload_index: 1, parts: [], completed: true}}
    else
      error ->
        {error, state}
    end
  end
end
