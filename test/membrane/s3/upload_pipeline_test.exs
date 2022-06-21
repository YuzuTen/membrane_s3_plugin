defmodule Membrane.S3.UploadPipelineTest do
  use ExUnit.Case
  import Membrane.Testing.Assertions
  alias Membrane.Testing.Pipeline
  alias Membrane.ParentSpec

  require Membrane.Logger

  @moduletag :capture_log

  test "basic pipeline" do
    children = [
      source: %Membrane.File.Source{
        location: "./test/sample_file.txt"
      },
      destination: %Membrane.S3.Sink{
        bucket: "membrane-s3-plugin-test-bucket-us-east-1",
        path: "example.txt",
        ex_aws: ExAws,
      }
    ]

    {:ok, pipeline} = Pipeline.start_link(links: ParentSpec.link_linear(children))

    assert_start_of_stream(pipeline, :destination, :input)
    assert_end_of_stream(pipeline, :destination)
    Pipeline.terminate(pipeline, blocking?: true)
  end
end
