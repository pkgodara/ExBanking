defmodule ExBanking do
  @moduledoc """
  Banking APIs
  """
  alias ExBanking.GenAccount
  alias ExBanking.UserSupervisor

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    user
    |> String.to_atom()
    |> create_user()
  end

  def create_user(account) when is_atom(account) do
    case create(account) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        {:error, :user_already_exists}
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) and amount > 0 do
    do_deposit(user, amount, currency)
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
      when is_binary(user) and is_number(amount) and is_binary(currency) and amount > 0 do
    do_withdraw(user, amount, currency)
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
      when is_binary(from) and is_binary(to) and is_number(amount) and is_binary(currency) and
             amount > 0 do
    do_send(from, to, amount, currency)
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  def balances(user) do
    with {:ok, account} <- get_account(user) do
      GenAccount.balances(account)
    end
  end

  ###     Priv fns

  defp create(account) do
    UserSupervisor.start_child({GenAccount, name: account})
  end

  defp do_deposit(user, amount, currency) do
    with {:ok, account} <- get_account(user),
         :ok <- can_handle_load?(account),
         {:ok, balance} <- GenAccount.deposit(account, amount, currency) do
      {:ok, num_round(balance)}
    end
  end

  defp do_withdraw(user, amount, currency) do
    with {:ok, account} <- get_account(user),
         :ok <- can_handle_load?(account),
         {:ok, balance} <- GenAccount.withdraw(account, amount, currency) do
      {:ok, num_round(balance)}
    end
  end

  defp do_send(from, to, amount, currency) do
    with {:ok, from_account} <- get_account(from, :sender_does_not_exist),
         {:ok, to_account} <- get_account(to, :receiver_does_not_exist),
         :ok <- can_handle_load?(from_account, :too_many_requests_to_sender),
         :ok <- can_handle_load?(to_account, :too_many_requests_to_receiver),
         {:ok, from_bal} <- GenAccount.withdraw(from_account, amount, currency) do
      {:ok, to_bal} = GenAccount.deposit(to_account, amount, currency)

      {:ok, num_round(from_bal), num_round(to_bal)}
    end
  end

  defp do_get_balance(user, currency) do
    with {:ok, account} <- get_account(user),
         {:ok, bal} <- GenAccount.balance(account, currency) do
      {:ok, num_round(bal)}
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
    {:message_queue_len, message_queue_len} = GenAccount.pending_actions(account)

    if message_queue_len >= 10 do
      {:error, err_msg}
    else
      :ok
    end
  end

  defp num_round(num) do
    round(num * 100) / 100
  end
end
