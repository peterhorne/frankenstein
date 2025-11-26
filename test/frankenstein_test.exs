defmodule FrankensteinTest do
  use ExUnit.Case, async: true
  doctest Frankenstein

  defmodule ConfigurableExperiment do
    @behaviour Frankenstein.Experiment

    defdelegate validate(context, results), to: Frankenstein.Experiment.Default
    defdelegate publish(event_type, context, results), to: Frankenstein.Experiment.Default

    def sample(context) do
      context.enabled
    end
  end

  describe "run/1" do
    test "control == candidate" do
      experiment =
        Frankenstein.Experiment.new(
          Frankenstein.Experiment.Default,
          control: fn -> 215 + 1 end,
          candidate: fn -> 217 - 1 end
        )

      assert Frankenstein.run(experiment) == 216

      # TODO: assert telemetry
    end

    test "control != candidate" do
      experiment =
        Frankenstein.Experiment.new(
          Frankenstein.Experiment.Default,
          control: fn -> 215 + 1 end,
          candidate: fn -> 300 end
        )

      assert Frankenstein.run(experiment) == 216

      # TODO: assert telemetry
    end

    test "candidate raises an error" do
      experiment =
        Frankenstein.Experiment.new(
          Frankenstein.Experiment.Default,
          control: fn -> 216 end,
          candidate: fn -> raise RuntimeError, "candidate raised" end
        )

      assert Frankenstein.run(experiment) == 216

      # TODO: assert telemetry
    end

    # test "candidate times out" do
    #   # TODO: shorten experiment timeout

    #   experiment =
    #     Frankenstein.Experiment.new(
    #       Frankenstein.Experiment.Default,
    #       control: fn -> 216 end,
    #       candidate: fn -> Process.sleep(5_001) end
    #     )

    #   # TODO
    #   # assert Frankenstein.run(experiment) == 216

    #   # TODO: assert telemetry
    # end

    test "candidate is called when experiment is enabled" do
      pid = self()

      experiment =
        Frankenstein.Experiment.new(
          ConfigurableExperiment,
          control: fn -> 216 end,
          candidate: fn -> send(pid, :candidate_called) end,
          context: %{enabled: true}
        )

      Frankenstein.run(experiment)

      assert_received :candidate_called
    end

    # TODO: need to use Observation instead of Result
    @tag :skip
    test "candidate is not called when experiment is disabled" do
      pid = self()

      experiment =
        Frankenstein.Experiment.new(
          ConfigurableExperiment,
          control: fn -> 216 end,
          candidate: fn -> send(pid, :candidate_called) end,
          context: %{enabled: false}
        )

      Frankenstein.run(experiment)

      refute_received :candidate_called
    end
  end
end
