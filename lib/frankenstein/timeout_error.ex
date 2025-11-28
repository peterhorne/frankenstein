defmodule Frankenstein.TimeoutError do
  @moduledoc """
  Returned when a test is terminated early due to a custom timeout.
  """

  defexception [:message]

  @impl true
  def exception(timeout) do
    message = "Test timed out after #{timeout}ms"
    %__MODULE__{message: message}
  end
end
