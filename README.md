# ExBanking

Simple In-Memory Banking in Elixir,

Supports `deposit`, `withdraw` and `send` actions with *in-memory transactional atomicity*.


## Interact?
Get/update deps `mix deps.get`
Simply can run  `iex -S mix` in the top directory


## Play with it 

```
import ExBanking
create_user "a"
create_user "b"
deposit "a", 10, "usd"
send "a", "b", 10, "usd"
get_balance "a", "usd"
balances "a"

Task.async(fn -> IO.inspect deposit "a", 10, "usd" end)

(1..13) |> Enum.each(fn _ -> Task.async(fn -> IO.inspect deposit "a", 10, "usd" end) end)

(1..3) |> Enum.each(fn _ -> Task.async(fn -> IO.inspect send "a", "b", 10, "usd" end) end)

(1..3) |> Enum.each(fn _ -> Task.async(fn -> IO.inspect(send("b", "a", 20, "usd"), label: :send_b_a) end) end)

(1..13) |> Enum.each(fn _ ->
    Task.async(fn -> IO.inspect(deposit("a", 10, "usd"), label: :deposit_a) end)
    Task.async(fn -> IO.inspect(deposit("b", 0.10, "usd"), label: :deposit_b) end)
    Task.async(fn -> IO.inspect(send("a", "b", 10, "usd"), label: :send_a_b) end)
  end)
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_banking` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_banking, "~> 0.1.0"}
  ]
end
```


