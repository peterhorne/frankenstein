defmodule FrankensteinTest do
  use ExUnit.Case, async: true
  doctest Frankenstein

  describe "run/1" do
    # TODO: add a test to verify match
    test "simple usage works" do
      experiment =
        Frankenstein.Experiment.new(
          Frankenstein.Experiment.Default,
          control: fn -> 215 + 1 end,
          candidate: fn -> 217 - 1 end
        )

      assert Frankenstein.run(experiment) == 216
    end

    test "candidate crashes, should not affect control" do
      experiment =
        Frankenstein.Experiment.new(
          Frankenstein.Experiment.Default,
          control: fn -> 216 end,
          candidate: fn -> raise RuntimeError, "candidate raised" end
        )

      assert Frankenstein.run(experiment) == 216
    end

    test "sample/1 would skip" do
      defmodule SkippableExperiment do
        @behaviour Frankenstein.Experiment

        defdelegate validate(context, results), to: Frankenstein.Experiment.Default
        defdelegate publish(event_type, context, results), to: Frankenstein.Experiment.Default

        def sample(context) do
          context.should_sample || send(context.pid, {context.pid, :skipped})
        end
      end

      pid = self()

      experiment =
        Frankenstein.Experiment.new(
          SkippableExperiment,
          control: fn -> 216 end,
          candidate: fn -> flunk("should not be called") end,
          context: %{should_sample: false, pid: pid}
        )

      assert Frankenstein.run(experiment) == 216

      assert_received {^pid, :skipped}

      purge(SkippableExperiment)
    end

    # Frankenstein.Experiment.new(TestExperiment, control:, candidate:, context: %{pid: self()})

    # test "experiment takes too long" do
    #   assert Frankenstein.run(
    #            control: fn -> 216 end,
    #            # TODO: change it to a smaller timeout in test
    #            candidate: fn -> Process.sleep(5_001) end
    #          ) == 216
    # end
  end

  defp purge(module) do
    :code.purge(module)
    :code.delete(module)
  end
end
