defmodule FrankensteinTest do
  use ExUnit.Case, async: true

  alias Frankenstein.Experiment

  describe "run/1" do
    test "candidate matches control" do
      experiment = %Experiment{
        name: :my_experiment,
        control: fn -> 215 + 1 end,
        candidate: fn -> 217 - 1 end
      }

      assert Frankenstein.run(experiment) == 216

      # TODO: assert telemetry
    end

    test "candidate doesn't match control" do
      experiment = %Experiment{
        name: :my_experiment,
        control: fn -> 215 + 1 end,
        candidate: fn -> 300 end
      }

      assert Frankenstein.run(experiment) == 216

      # TODO: assert telemetry
    end

    test "candidate raises an error" do
      experiment = %Experiment{
        name: :my_experiment,
        control: fn -> 215 + 1 end,
        candidate: fn -> raise "borked" end
      }

      assert Frankenstein.run(experiment) == 216

      # TODO: assert telemetry
    end

    test "control raises an error" do
      experiment = %Experiment{
        name: :my_experiment,
        control: fn -> raise "borked" end,
        candidate: fn -> 432 / 2 end
      }

      assert_raise RuntimeError, fn -> Frankenstein.run(experiment) end

      # TODO: assert telemetry
    end

    test "experiment is enabled" do
      pid = self()

      experiment = %Experiment{
        name: :my_experiment,
        control: fn -> 216 end,
        candidate: fn ->
          send(pid, :candidate_called)
          108 * 2
        end,
        enabled?: true
      }

      Frankenstein.run(experiment)

      assert_receive :candidate_called, 1

      # TODO: assert telemetry
    end

    test "experiment is disabled" do
      pid = self()

      experiment = %Experiment{
        name: :my_experiment,
        control: fn -> 216 end,
        candidate: fn -> send(pid, :candidate_called) end,
        enabled?: false
      }

      Frankenstein.run(experiment)

      refute_receive :candidate_called, 1

      # TODO: assert no telemetry
    end

    test "candidate times out" do
      pid = self()

      experiment = %Experiment{
        name: :my_experiment,
        control: fn -> 215 + 1 end,
        candidate: fn ->
          Process.sleep(10)
          send(pid, :candidate_called)
        end,
        timeout_ms: 5
      }

      Frankenstein.run(experiment)

      refute_receive :candidate_called, 20

      # TODO: assert telemetry
    end
  end
end
