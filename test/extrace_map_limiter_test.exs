defmodule Extrace.MapLimiterTest do
  use ExUnit.Case
  alias Extrace.MapLimiter

  import Extrace, only: [format: 1]

  test "install - limit - remove" do
    ts = :os.timestamp()
    ts_str = format_timestamp(ts)
    datetime = DateTime.new!(~D[2018-10-28], ~T[02:30:00])

    old_string = "\n#{ts_str} <0.1.0> < ~~U[2018-10-28 02:30:00Z]\n"
    assert old_string == format({:trace_ts, pid(0, 1, 0), :receive, datetime, ts}) |> to_string()

    assert :ok = MapLimiter.install()

    assert :ok = MapLimiter.limit(datetime, [:year, :month, :day])

    assert "\n#{ts_str} <0.1.0> < #DateTime<year: 2018, month: 10, day: 28, ...>\n" ==
             format({:trace_ts, pid(0, 1, 0), :receive, datetime, ts}) |> to_string()

    assert :ok = MapLimiter.limit(datetime, [:day])

    assert "\n#{ts_str} <0.1.0> < #DateTime<day: 28, ...>\n" ==
             format({:trace_ts, pid(0, 1, 0), :receive, datetime, ts}) |> to_string()

    assert :ok = MapLimiter.limit(DateTime, %{__struct__: DateTime}, [:day])

    assert "\n#{ts_str} <0.1.0> < #DateTime<day: 28, ...>\n" ==
             format({:trace_ts, pid(0, 1, 0), :receive, datetime, ts}) |> to_string()

    assert :ok = MapLimiter.limit(datetime, :none)
    assert old_string == format({:trace_ts, pid(0, 1, 0), :receive, datetime, ts}) |> to_string()

    assert :ok = MapLimiter.limit(datetime, :all)

    assert "\n#{ts_str} <0.1.0> < #DateTime<...>\n" ==
             format({:trace_ts, pid(0, 1, 0), :receive, datetime, ts}) |> to_string()

    assert true = MapLimiter.remove(DateTime)
    assert old_string == format({:trace_ts, pid(0, 1, 0), :receive, datetime, ts}) |> to_string()
  end

  defp pid(a, b, c) do
    :erlang.list_to_pid(~c'<#{a}.#{b}.#{c}>')
  end

  defp format_timestamp(ts) do
    to_hms(ts) |> format_hms()
  end

  defp to_hms({_, _, micro} = stamp) do
    {_, {h, m, secs}} = :calendar.now_to_local_time(stamp)
    seconds = rem(secs, 60) + micro / 1_000_000
    {h, m, seconds}
  end

  defp format_hms({h, m, s}) do
    :io_lib.format(~c'~2.2.0w:~2.2.0w:~9.6.0f', [h, m, s])
  end
end
