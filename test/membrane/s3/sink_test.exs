defmodule ExAws.HappyPath do
  # This is for verification that we start the stream
  def request(
        %ExAws.Operation.S3{
          body: _,
          bucket: _,
          headers: %{},
          http_method: :post,
          params: %{},
          parser: _,
          path: "test.txt",
          resource: "uploads",
          service: :s3,
          stream_builder: nil
        },
        []
      ) do
    {
      :ok,
      %{
        body: %{
          bucket: "membrane-example",
          key: "test.txt",
          upload_id: "aws_id_example"
        },
        headers: [
          {
            "x-amz-id-2",
            "HQ/79xGFiXpKzYGvZrQz4sVGwQDIsqjPJSPL+LWNtYp0G+cgypl4G8rBwrBnqg/HPXfpId9Bqm4="
          },
          {"x-amz-request-id", "K58W37AYQ2TMJY11"},
          {"Date", "Sat, 21 May 2022 08:25:55 GMT"},
          {"x-amz-server-side-encryption", "AES256"},
          {"Transfer-Encoding", "chunked"},
          {"Server", "AmazonS3"}
        ],
        status_code: 200
      }
    }
  end

  # This is for validating that we respond to a multipart put request
  def request(
        %ExAws.Operation.S3{
          body: _,
          bucket: _,
          headers: %{},
          http_method: :put,
          params: %{},
          parser: _,
          path: "multipart.bin",
          resource: "",
          service: :s3,
          stream_builder: nil
        },
        []
      ) do
    {
      :ok,
      %{
        body: %{
          bucket: "membrane-example",
          key: "multipart.bin",
          upload_id: "aws_id_example"
        },
        headers: [
          {
            "x-amz-id-2",
            "HQ/79xGFiXpKzYGvZrQz4sVGwQDIsqjPJSPL+LWNtYp0G+cgypl4G8rBwrBnqg/HPXfpId9Bqm4="
          },
          {"x-amz-request-id", "K58W37AYQ2TMJY11"},
          {"Date", "Sat, 21 May 2022 08:25:55 GMT"},
          {"x-amz-server-side-encryption", "AES256"},
          {"Transfer-Encoding", "chunked"},
          {"Server", "AmazonS3"},
          {"etag", "\"A1234\""}
        ],
        status_code: 200
      }
    }
  end
end

defmodule ExAws.RaiseIfRequestInvoked do
  def request(_, _),
    do: raise(ShouldNotBeInvokedError, message: "AWS should not be invoked in this case")
end

defmodule ShouldNotBeInvokedError do
  defexception message: "Default Exception Message, override in your test for clarity"
end

defmodule Membrane.S3.SinkTest do
  use ExUnit.Case, async: true

  alias Membrane.S3.Sink

  @moduletag :capture_log

  doctest Sink

  test "module exists" do
    assert is_list(Sink.module_info())
  end

  @clean_state %{
    bucket: "membrane-example",
    path: "test.txt",
    s3_opts: [],
    aws_config: [],
    upload_id: nil,
    ex_aws: ExAws.HappyPath
  }

  test "handle_stopped_to_prepared" do
    assert {:ok, %{upload_id: "aws_id_example"}} =
             Sink.handle_stopped_to_prepared(%{}, @clean_state)
  end

  @typical_input_queue_buffer_size 60_000
  @short_payload :crypto.strong_rand_bytes(@typical_input_queue_buffer_size)
  @minimum_aws_chunk_size 5 * 1024 * 1024

  @most_of_a_chunk_size @minimum_aws_chunk_size - 1
  @most_of_a_chunk :crypto.strong_rand_bytes(@most_of_a_chunk_size)
                   |> String.codepoints()
                   |> Enum.chunk_every(@typical_input_queue_buffer_size)
                   |> Enum.map(&Enum.join/1)

  describe "handle_write" do
    test "does not upload when the supplied buffer isn't big enough" do
      assert {{:ok, [demand: {:input, 5_242_880}]}, _state} =
               Sink.handle_write(
                 :input,
                 %Membrane.Buffer{payload: @short_payload},
                 # We don't actually use the context
                 %{},
                 %{
                   # default
                   chunk_size: @minimum_aws_chunk_size,
                   current_chunk: [],
                   current_chunk_size: 0,
                   ex_aws: ExAws.RaiseIfRequestInvoked
                 }
               )
    end

    test "uploads when the supplied buffer finally meets the target" do
      assert {{:ok, [demand: {:input, 5_242_880}]}, _state} =
               Sink.handle_write(
                 :input,
                 %Membrane.Buffer{payload: @short_payload},
                 # We don't actually use the context
                 %{},
                 %{
                   # default
                   chunk_size: @minimum_aws_chunk_size,
                   current_chunk: @most_of_a_chunk,
                   current_chunk_size: @most_of_a_chunk_size,
                   ex_aws: ExAws.HappyPath,
                   # needed for the upload_chunk call
                   bucket: "membrane-example",
                   path: "multipart.bin",
                   s3_opts: [],
                   aws_config: [],
                   upload_id: nil,
                   parts: [],
                   upload_index: 1
                 }
               )
    end
  end
end
