# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2022-06-25
### Added
- Initial Membrane S3 Sink implementation
- CI process including mix credo, mix format, and dialyzer

## [0.1.1] - 2022-08-15
### Added
- Moved AWS call to complete the stream to handle_end_of_stream/3 so that files will upload even if the pipeline isn't
explicitly stopped. Allows this plugin to be more friendly with dynamic pipelines.

## [0.1.2] - 2022-11-24
### Fixed
- When Membrane's input queue intercepts the demand we send, it sends a demand for 60,000 bytes upstream. We now accumulate
all of the buffers in the Sink until we meet the minimum chunk size. This _may_ create some issues when on slow connections, but
doing a streaming upload raises some complications we haven't yet had time to dig into.


