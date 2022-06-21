defmodule Membrane.S3.Plugin.MixProject do
  use Mix.Project

  @version "0.0.1"
  @github_url "https://github.com/YuzuTen/membrane_s3_plugin"

  def project do
    [
      app: :membrane_s3_plugin,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),

      # hex
      description: "Membrane Multimedia Framework plugin for S3",
      package: package(),

      # docs
      name: "Membrane S3 plugin",
      source_url: @github_url,
      homepage_url: "https://www.yuzuten.com/",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        LICENSE: [
          title: "License"
        ]
      ],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.File]
    ]
  end

  defp package do
    [
      maintainers: ["Jason Truesdell"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws_s3, "~> 2.3"},
      {:ex_doc, "~> 0.28.4"},
      {:membrane_core, "~> 0.10"},
      # These are the default dependencies that ex_aws uses. They are not included in the :prod build
      # Because downstream clients may elect override them. Your application should include these in your own
      # mix.exs if you're happy with the defaults, or provide your own custom alternative.
      {:hackney, ">= 0.0.0", only: [:dev, :test]},
      {:jason, ">= 0.0.0", only: [:dev, :test]},
      {:sweet_xml, ">= 0.0.0", optional: true},
      {:membrane_file_plugin, "~> 0.12.0", only: [:dev, :test]},
    ]
  end
end
