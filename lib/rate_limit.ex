defmodule ExBanking.RateLimit do
  @moduledoc """
  Rate limit functional calls
  """

  use GenServer

  # Client

  def start_link(default \\ %{}) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def inc(account) do
    GenServer.cast(__MODULE__, {:inc, account})
  end

  def dec(account) do
    GenServer.cast(__MODULE__, {:dec, account})
  end

  def get(account) do
    GenServer.call(__MODULE__, {:get, account})
  end

  def reset(account) do
    GenServer.cast(__MODULE__, {:reset, account})
  end

  # Server (callbacks)

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:inc, account}, state) do
    count = Map.get(state, account, 0) + 1

    {:noreply, Map.put(state, account, count)}
  end

  def handle_cast({:dec, account}, state) do
    count = Map.get(state, account, 0) - 1

    {:noreply, Map.put(state, account, count)}
  end

  def handle_cast({:reset, account}, state) do
    {:noreply, Map.put(state, account, 0)}
  end

  @impl true
  def handle_call({:get, account}, _from, state) do
    {:reply, Map.get(state, account, 0), state}
  end
end
