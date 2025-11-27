defmodule Frankenstein.Publisher do
  def listen(experiment) do
    :timer.send_after(experiment.timeout_ms, :timeout)
    listen_and_publish(experiment, {nil, nil})
  end

  def listen_and_publish(experiment, {control, candidate})
      when is_nil(control) or is_nil(candidate) do
    receive do
      {:control, result} -> {result, candidate}
      {:candidate, result} -> {control, result}
      :timeout -> {control || :timeout, candidate || :timeout}
    end
    |> then(&listen_and_publish(experiment, &1))
  end

  def listen_and_publish(experiment, {control, candidate}) do
    IO.inspect(
      [
        control: control,
        candidate: candidate,
        match: experiment.compare.(control, candidate)
      ],
      label: "== publish"
    )
  end
end
