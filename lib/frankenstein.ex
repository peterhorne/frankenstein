defmodule Frankenstein do
  @moduledoc """
  Documentation for `Frankenstein`.
  """

  require Logger

  alias Frankenstein.Experiment
  alias Frankenstein.Publisher

  @telemetry_prefix [:frankenstein]

  def run(%Experiment{enabled?: false} = experiment) do
    experiment.control.()
  end

  def run(%Experiment{enabled?: true} = experiment) do
    publisher_pid =
      spawn(fn -> Publisher.start(experiment) end)

    spawn(fn ->
      :timer.kill_after(experiment.timeout_ms)

      try do
        telemetry_metadata = %{experiment: experiment.name, test: :candidate}

        value =
          :telemetry.span(
            @telemetry_prefix ++ [:test],
            telemetry_metadata,
            fn -> {experiment.candidate.(), telemetry_metadata} end
          )

        send(publisher_pid, {:candidate, {:ok, value}})
      rescue
        e ->
          send(publisher_pid, {:candidate, {:error, e}})
      end
    end)

    try do
      telemetry_metadata = %{experiment: experiment.name, test: :control}

      value =
        :telemetry.span(
          @telemetry_prefix ++ [:test],
          telemetry_metadata,
          fn ->
            {experiment.control.(), telemetry_metadata}
          end
        )

      send(publisher_pid, {:control, {:ok, value}})
      value
    rescue
      e ->
        send(publisher_pid, {:control, {:error, e}})
        reraise e, __STACKTRACE__
    end
  end
end
