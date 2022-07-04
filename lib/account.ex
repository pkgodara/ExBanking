defmodule ExBanking.Account do
  @moduledoc """
  User accounts interface
  """

  alias ExBanking.UserSupervisor
  alias ExBanking.Mutex, as: ExMutex

  use Agent

  def start_link(account) do
    UserSupervisor.start_child(Agent, [fn -> %{} end, [name: account]])
  end

  def deposit(account, amount, currency) do
    :ok =
      Mutex.under(ExMutex, account, fn ->
        do_deposit(account, amount, currency)
      end)

    {:ok, Agent.get(account, fn state -> state end)}
  end

  def withdraw(account, amount, currency) do
    result =
      Mutex.under(ExMutex, account, fn ->
        do_withdraw(account, amount, currency)
      end)

    case result do
      :ok -> {:ok, Agent.get(account, fn state -> state end)}
      err -> err
    end
  end

  def transfer(account, to_account, amount, currency) do
    Mutex.under_all(ExMutex, [account, to_account], fn ->
      with :ok <- do_withdraw(account, amount, currency),
           :ok <- do_deposit(to_account, amount, currency) do
        {:ok, Agent.get(account, fn state -> state end),
         Agent.get(to_account, fn state -> state end)}
      end
    end)
  end

  def get_balance(account, currency) do
    account
    |> Agent.get(fn state -> state end)
    |> Map.get(currency, 0)
  end

  def balances(account) do
    Agent.get(account, fn state -> state end)
  end

  ### Privates

  defp do_deposit(account, amount, currency) do
    Agent.update(account, fn state ->
      prev = Map.get(state, currency, 0)

      Map.put(state, currency, prev + amount)
    end)
  end

  defp do_withdraw(account, amount, currency) do
    prev_bal = account |> Agent.get(fn state -> state end) |> Map.get(currency, 0)

    if prev_bal >= amount do
      Agent.update(account, fn state ->
        prev = Map.get(state, currency, 0)
        Map.put(state, currency, prev - amount)
      end)
    else
      {:error, :not_enough_money}
    end
  end
end
