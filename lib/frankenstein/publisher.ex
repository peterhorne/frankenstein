defmodule Frankenstein.Publisher do
  @telemetry_prefix [:frankenstein]

  def start(experiment) do
    :timer.send_after(experiment.timeout_ms, :timeout)

    telemetry_metadata = %{experiment: experiment.name}

    :telemetry.span(
      @telemetry_prefix ++ [:experiment],
      telemetry_metadata,
      fn ->
        results = listen({nil, nil}, experiment)
        match? = compare(results, experiment.compare)
        telemetry_metadata = Map.put(telemetry_metadata, :match?, match?)
        {:ok, telemetry_metadata}
      end
    )
  end

  def listen(_acc = {control, candidate}, experiment)
      when is_nil(control) or is_nil(candidate) do
    receive do
      {:control, result} ->
        {result, candidate}

      {:candidate, result} ->
        {control, result}

      :timeout ->
        {
          control || {:error, Frankenstein.TimeoutError.exception(experiment.timeout_ms)},
          candidate || {:error, Frankenstein.TimeoutError.exception(experiment.timeout_ms)}
        }
    end
    |> listen(experiment)
  end

  def listen(result, _experiment), do: result

  def compare({control = {:ok, _}, candidate = {:ok, _}}, comparison_fn),
    do: comparison_fn.(control, candidate)

  def compare(_, _), do: false
end
