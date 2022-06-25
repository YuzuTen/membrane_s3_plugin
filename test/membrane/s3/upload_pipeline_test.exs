defmodule Membrane.S3.UploadPipelineTest do
  use ExUnit.Case, async: false

  import Membrane.Testing.Assertions
  alias Membrane.Testing.Pipeline
  import Mox

  alias Membrane.ParentSpec

  require Membrane.Logger

  @moduletag :capture_log

  # , :verify_on_exit!
  setup :set_mox_global

  test "basic pipeline" do
    children = [
      source: %Membrane.File.Source{
        location: "./test/sample_file.txt"
      },
      destination: %Membrane.S3.Sink{
        bucket: "membrane-s3-plugin-test-bucket-us-east-1",
        path: "example.txt",
        ex_aws: ExAwsMock
      }
    ]

    ExAwsMock
    |> expect(
      :request,
      fn %ExAws.Operation.S3{}, _ ->
        {
          :ok,
          %{
            body: %{
              upload_id: 12_345
            }
          }
        }
      end
    )
    |> expect(:request, fn %ExAws.Operation.S3{}, _ ->
      {:ok, %{headers: [{"ETag", "\"A1234\""}]}}
    end)
    |> expect(:request, fn %ExAws.Operation.S3{}, _ -> {:ok, %{headers: []}} end)

    {:ok, pipeline} = Pipeline.start_link(links: ParentSpec.link_linear(children))

    assert_start_of_stream(pipeline, :destination, :input)
    assert_end_of_stream(pipeline, :destination)
    Pipeline.terminate(pipeline, blocking?: true)
  end
end
