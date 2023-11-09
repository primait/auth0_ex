defmodule PrimaAuth0Ex.TestSupport.TimeUtils do
  @moduledoc false

  def one_hour_ago, do: shifted_by_hours(-1)
  def two_hours_ago, do: shifted_by_hours(-2)
  def now, do: shifted_by_hours(0)
  def in_one_hour, do: shifted_by_hours(1)
  def in_two_hours, do: shifted_by_hours(2)

  def shifted_by_hours(n) do
    Timex.now() |> Timex.shift(hours: n) |> Timex.to_unix()
  end

  def shifted_by_seconds(n) do
    Timex.now() |> Timex.shift(seconds: n) |> Timex.to_unix()
  end
end
