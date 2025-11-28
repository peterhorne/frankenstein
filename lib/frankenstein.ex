defmodule Frankenstein do
  @moduledoc """
  Documentation for `Frankenstein`.
  """

  require Logger

  alias Frankenstein.Experiment
  alias Frankenstein.Lab
  alias Frankenstein.Telemetry

  def run(%Experiment{enabled?: false} = experiment) do
    experiment.control.()
  end

  def run(%Experiment{enabled?: true} = experiment) do
    pid = self()

    lab_pid =
      spawn(fn -> Lab.start(experiment, pid) end)

    try do
      value = Telemetry.span_test(experiment, :control, experiment.control)
      send(lab_pid, {:control, {:ok, value}})
      value
    rescue
      e ->
        send(lab_pid, {:control, {:error, e}})
        reraise e, __STACKTRACE__
    end
  end
end
