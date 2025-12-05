defmodule Frankenstein.Telemetry do
  @telemetry_prefix [:frankenstein]

  def publish_result(experiment, match) do
    metadata = %{experiment: experiment.name}
    event_name = @telemetry_prefix ++ [:experiment]
    measurements = %{match: match}
    :telemetry.execute(event_name, measurements, metadata)
  end

  def span_test(experiment, test_name, f) do
    telemetry_metadata = %{experiment: experiment.name, test: test_name}

    :telemetry.span(
      @telemetry_prefix ++ [:test],
      telemetry_metadata,
      fn ->
        {f.(), telemetry_metadata}
      end
    )
  end
end
