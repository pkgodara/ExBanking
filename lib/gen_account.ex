defmodule ExBanking.GenAccount do
  @moduledoc """
  Account for user
  """
  use GenServer

  @timeout 10_000

  # Client
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def balances(account) when is_atom(account) do
    GenServer.call(account, :balances, @timeout)
  end

  def pending_actions(account) when is_atom(account) do
    account
    |> Process.whereis()
    |> :erlang.process_info(:message_queue_len)
  end

  def deposit(account, amount, currency) when is_atom(account) do
    GenServer.call(account, {:deposit, amount, currency}, @timeout)
  end

  def withdraw(account, amount, currency) when is_atom(account) do
    GenServer.call(account, {:withdraw, amount, currency}, @timeout)
  end

  def balance(account, amount) when is_atom(account) do
    GenServer.call(account, {:balance, amount}, @timeout)
  end

  # Server

  @impl true
  def init(init_arg \\ %{}) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call(:balances, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    new_bal = Map.get(state, currency, 0) + amount
    new_state = Map.put(state, currency, new_bal)

    {:reply, {:ok, new_bal}, new_state}
  end

  def handle_call({:withdraw, amount, currency}, _from, state) do
    new_bal = Map.get(state, currency, 0) - amount

    if new_bal < 0 do
      {:reply, {:error, :not_enough_money}, state}
    else
      new_state = Map.put(state, currency, new_bal)
      {:reply, {:ok, new_bal}, new_state}
    end
  end

  def handle_call({:balance, currency}, _from, state) do
    {:reply, {:ok, Map.get(state, currency, 0)}, state}
  end
end
