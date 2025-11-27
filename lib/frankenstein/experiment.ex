defmodule Frankenstein.Experiment do
  @enforce_keys [:name, :control, :candidate]
  defstruct [:name, :control, :candidate, compare: &==/2, enabled?: true, timeout_ms: 1_000]
end
