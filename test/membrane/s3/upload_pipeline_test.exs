defmodule Membrane.S3.UploadPipelineTest do
  use ExUnit.Case, async: false

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions
  alias Membrane.Testing
  import Mox

  require Membrane.Logger

  @moduletag :capture_log

  # , :verify_on_exit!
  setup :set_mox_global

  test "basic pipeline" do
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

    pipeline =
      Testing.Pipeline.start_link_supervised!(
        spec:
          child(:source, %Membrane.File.Source{
            location: "./test/sample_file.txt"
          })
          |> child(:destination, %Membrane.S3.Sink{
            bucket: "membrane-s3-plugin-test-bucket-us-east-1",
            path: "example.txt",
            ex_aws: ExAwsMock
          })
      )

    assert_start_of_stream(pipeline, :destination, :input)
    assert_end_of_stream(pipeline, :destination)
    Testing.Pipeline.terminate(pipeline)
  end
end
