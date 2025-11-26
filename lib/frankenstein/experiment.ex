defmodule Frankenstein.Experiment do
  defstruct [:module, :control, :candidate, :context]

  alias Frankenstein.Experiment.Default
  alias Frankenstein.Experiment.Result

  @type t() :: %__MODULE__{
          module: module(),
          control: fun(),
          candidate: fun(),
          context: map()
        }

  @type context() :: map()
  @type event_type() :: :match | :mismatch | :skipped

  @callback sample(context()) :: boolean()
  @callback validate(context(), {Result.t(), Result.t()}) :: :ok | :mismatch
  @callback publish(event_type(), context(), {Result.t(), Result.t()}) :: :ok | {:error, term()}

  # TODO: validate function arity with is_function/2
  # TODO: maybe refactor it to explicitly take in `{module \\ Default, opts}`?
  def new(module \\ Default, opts) do
    control = Keyword.fetch!(opts, :control)
    candidate = Keyword.fetch!(opts, :candidate)
    context = Keyword.get(opts, :context, %{})

    %__MODULE__{
      module: module,
      control: control,
      candidate: candidate,
      context: context
    }
  end
end
