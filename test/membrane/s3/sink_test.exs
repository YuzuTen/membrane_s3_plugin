defmodule ExAws.HappyPath do
  def request(
        %ExAws.Operation.S3{
          body: "",
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
end
