# Membrane S3 Plugin

![Membrane S3 Plugin CI Workflow](https://github.com/YuzuTen/membrane_s3_plugin/actions/workflows/ci.yml/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/membrane_s3_plugin.svg)](https://hex.pm/packages/membrane_s3_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_s3_plugin/)

This plugin provides a Membrane Sink that writes to Amazon S3, or other object stores that use the AWS S3 API.
It will eventually also provide a membrane Source that reads from S3, but my current project doesn't need it yet.

It is designed to work with the [Membrane Multimedia Framework](https://www.membraneframework.org/).

## Installation

The package can be installed by adding `membrane_s3_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_s3_plugin, "~> 0.1"}
  ]
end
```

This library depends on [ex_aws_s3](https://github.com/ex-aws/ex_aws_s3/)
and [ex_aws](https://github.com/ex-aws/ex_aws_/).
[ex_aws](https://github.com/ex-aws/ex_aws_/) requires a http client. The default
is [hackney](https://hexdocs.pm/hackney/).

If you are content with hackney as your http client, add `{:hackney, "~> 1.18"}` to your list of dependencies
in `mix.exs`. For other http
clients, you may override the `:ex_aws, :http_client` configuration to point to a module that implements the
[`ExAws.Request.HttpClient`](https://hexdocs.pm/ex_aws/ExAws.Request.HttpClient.html) behavior.

Because this library does no transcoding or packaging, no non-BEAM dependencies are required.

## Usage example

If you have AWS environment variables set up [(see ExAws documentation)](https://github.com/ex-aws/ex_aws), and include the [membrane_file_plugin](https://hexdocs.pm/) in your
`mix.exs` dependencies, you can write a simple pipeline to write to S3:

````elixir
defmodule Membrane.ReleaseTest.Pipeline do
  use Membrane.Pipeline

  alias Membrane.S3.Sink

  @impl true
  def handle_init(_) do
    children = [
      source: %Membrane.File.Source{
        location: "/tmp/input.raw"
      },
      sink: %Membrane.S3.Sink{
          bucket: "membrane-s3-plugin-test-bucket-us-east-1",
          path: "example.txt",
      }
    ]

    links = [
      link(:source)
      |> to(:sink)
    ]

    {{:ok, spec: %ParentSpec{children: children, links: links}}, %{}}
  end
end
````

More complex pipelines can be constructed by adding transcoders, packaging, and other components, and linking them together.
This minimalist example demonstrates how to construct a pipeline with no intermediate processing.

For additional configuration options, including alternate mechanisms, view the documentation.

## Contributing

1. Fork the [repository](https://github.com/YuzuTen/membrane_s3_plugin).
2. Clone the fork.
3. Make your changes.
4. Make sure to run `mix format`, `mix credo` and `mix dialyzer` and fix any issues that crop up.
5. Commit your changes. Add tests, please!
6. Create a [pull request](https://github.com/YuzuTen/membrane_s3_plugin/pulls).

## Documentation
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc).

The documentation is also published on [HexDocs](https://hexdocs.pm/membrane_s3_plugin).

## Changelog

Release history is in the project [Changelog](https://github.com/YuzuTen/membrane_s3_plugin/blob/main/CHANGELOG.md).

## Copyright and License

© 2022 YuzuTen LLC. Licensed under the [Apache license](LICENSE).

This plugin was originally written by [Jason Truesdell](https://github.com/JasonTrue) with support from [IndustrialML, Inc](https://www.industrialml.com/).

