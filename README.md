# Extrace.MapLimiter

**MapLimiter for Extrace**

## Installation

Adding `extrace_map_limiter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:extrace_map_limiter, "~> 0.1"}
  ]
end
```

## Usage

```elixir
iex(1)> :ok = Extrace.MapLimiter.install()
iex(2)> :ok = Extrace.MapLimiter.limit(DateTime, %{__struct__: DateTime}, [:day])
iex(3)> Extrace.calls({DateTime, :new!, :return_trace}, 10)
iex(4)> DateTime.new!(~D[2018-10-28], ~T[02:30:00])
~U[2018-10-28 02:30:00Z]

10:05:36.258872 <0.179.0> DateTime.new!(~D[2018-10-28], ~T[02:30:00])

10:05:36.263055 <0.179.0> DateTime.new!/2 --> #DateTime<day: 28, ...>
```
