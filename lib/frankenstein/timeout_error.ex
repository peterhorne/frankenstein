defmodule Frankenstein.TimeoutError do
  @moduledoc """
  Returned when a test is terminated early due to a custom timeout.
  """

  defexception [:timeout_ms]

  @impl true
  def message(%__MODULE__{timeout_ms: timeout_ms}) do
    "Test timed out after #{timeout_ms}ms"
  end
end
