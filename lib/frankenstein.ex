defmodule Frankenstein do
  @moduledoc """
  Documentation for `Frankenstein`.
  """

  require Logger

  alias Frankenstein.Experiment
  alias Frankenstein.Publisher

  def run(%Experiment{enabled?: false} = experiment) do
    experiment.control.()
  end

  def run(%Experiment{enabled?: true} = experiment) do
    publisher_pid = spawn(Publisher, :listen, [experiment])

    spawn(fn ->
      :timer.kill_after(experiment.timeout_ms)

      try do
        value = experiment.candidate.()
        send(publisher_pid, {:candidate, {:ok, value}})
      rescue
        e ->
          send(publisher_pid, {:candidate, {:error, e}})
      end
    end)

    try do
      value = experiment.control.()
      send(publisher_pid, {:control, {:ok, value}})
      value
    rescue
      e ->
        send(publisher_pid, {:control, {:error, e}})
        reraise e, __STACKTRACE__
    end
  end
end
