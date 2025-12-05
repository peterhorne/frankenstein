defmodule Frankenstein.Lab do
  alias Frankenstein.Telemetry

  def start(experiment) do
    pid = self()

    spawn(fn ->
      Process.monitor(pid)
      candidate = run_candidate(experiment)
      control = listen_for_control()
      match? = compare(control, candidate, experiment.compare)
      Telemetry.publish_result(experiment, match?)
    end)
  end

  defp run_candidate(experiment) do
    Telemetry.span_test(experiment, :candidate, fn ->
      run_with_timeout(experiment.candidate, experiment.timeout)
    end)
    |> then(&{:ok, &1})
  rescue
    e -> {:error, e}
  end

  defp listen_for_control do
    receive do
      {:control, value} -> value
      {:DOWN, _, :process, _, _} -> Kernel.exit(:shutdown)
    end
  end

  defp compare({:ok, _} = control, {:ok, _} = candidate, comparison_fn),
    do: comparison_fn.(control, candidate)

  defp compare({:ok, _} = _control, {:error, _} = _candidate, _), do: false

  defp compare(_, _, _), do: nil

  defp run_with_timeout(f, timeout) do
    task =
      Task.async(fn ->
        try do
          {:ok, f.()}
        rescue
          e -> {:error, e}
        end
      end)

    case Task.yield(task, timeout) do
      {:ok, {:ok, result}} ->
        result

      {:ok, {:error, e}} ->
        raise e

      nil ->
        Task.shutdown(task)
        raise Frankenstein.TimeoutError.exception(timeout_ms: timeout)
    end
  end
end
