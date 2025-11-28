defmodule Frankenstein.Lab do
  alias Frankenstein.Telemetry

  def start(experiment, parent_pid) do
    Process.monitor(parent_pid)

    Telemetry.span_experiment(experiment, fn ->
      candidate = run_candidate(experiment)
      control = listen_for_control()
      compare(control, candidate, experiment.compare)
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

  defp compare(control = {:ok, _}, candidate = {:ok, _}, comparison_fn),
    do: comparison_fn.(control, candidate)

  defp compare({:ok, _}, {:error, _}, _), do: false

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
        raise Frankenstein.TimeoutError.exception(timeout)
    end
  end
end
