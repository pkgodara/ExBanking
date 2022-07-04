defmodule ExBanking do
  @moduledoc """
  Banking APIs
  """
  alias ExBanking.Account
  alias ExBanking.RateLimit

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    account = String.to_atom(user)

    case Account.start_link(account) do
      {:ok, _pid} ->
        RateLimit.reset(account)
        :ok

      {:error, {:already_started, _pid}} ->
        {:error, :user_already_exists}
    end
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    with {:ok, account} <- get_account(user),
         :ok <- RateLimit.inc(account) do
      try do
        do_deposit(user, amount, currency)
      after
        RateLimit.dec(account)
      end
    end
  end

  def deposit(_user, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    with {:ok, account} <- get_account(user),
         :ok <- RateLimit.inc(account) do
      try do
        do_withdraw(user, amount, currency)
      after
        RateLimit.dec(account)
      end
    end
  end

  def withdraw(_user, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    do_get_balance(user, currency)
  end

  def get_balance(_user, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from, to, amount, currency)
      when is_binary(from) and is_binary(to) and is_number(amount) and is_binary(currency) do
    with {:ok, from_account} <- get_account(from, :sender_does_not_exist),
         {:ok, to_account} <- get_account(to, :receiver_does_not_exist),
         :ok <- RateLimit.inc(from_account),
         :ok <- RateLimit.inc(to_account) do
      try do
        do_send(from, to, amount, currency)
      after
        RateLimit.dec(from_account)
        RateLimit.dec(to_account)
      end
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  def balances(user) do
    with {:ok, account} <- get_account(user) do
      Account.balances(account)
    end
  end

  ###     Priv fns

  defp do_deposit(user, amount, currency) do
    with {:ok, account} <- get_account(user),
         :ok <- can_handle_load?(account),
         {:ok, balances} <- Account.deposit(account, amount, currency) do
      {:ok, Map.get(balances, currency, 0)}
    end
  end

  defp do_withdraw(user, amount, currency) do
    with {:ok, account} <- get_account(user),
         :ok <- can_handle_load?(account),
         {:ok, balances} <- Account.withdraw(account, amount, currency) do
      {:ok, Map.get(balances, currency, 0)}
    end
  end

  defp do_send(from, to, amount, currency) do
    with {:ok, from_account} <- get_account(from, :sender_does_not_exist),
         {:ok, to_account} <- get_account(to, :receiver_does_not_exist),
         :ok <- can_handle_load?(from_account, :too_many_requests_to_sender),
         :ok <- can_handle_load?(to_account, :too_many_requests_to_receiver),
         {:ok, from_bal, to_bal} <- Account.transfer(from_account, to_account, amount, currency) do
      {:ok, Map.get(from_bal, currency, 0), Map.get(to_bal, currency, 0)}
    end
  end

  defp do_get_balance(user, currency) do
    with {:ok, account} <- get_account(user) do
      Account.get_balance(account, currency)
    end
  end

  defp get_account(user, err_msg \\ :user_does_not_exist) do
    account = String.to_atom(user)

    case Process.whereis(account) do
      nil ->
        {:error, err_msg}

      _pid ->
        {:ok, account}
    end
  end

  defp can_handle_load?(account, err_msg \\ :too_many_requests_to_user) do
    pending = RateLimit.get(account)

    if pending > 10 do
      {:error, err_msg}
    else
      :ok
    end
  end
end
