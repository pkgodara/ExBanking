defmodule ExBankingTest do
  @moduledoc false
  use ExUnit.Case, async: true

  describe "create_user/1" do
    test "creates user" do
      account = "user1"
      assert :ok = ExBanking.create_user(account)

      assert :ok = ExBanking.create_user(:account)
    end

    test "error on duplicate account" do
      account = "user-1"
      assert :ok = ExBanking.create_user(account)
      assert {:error, :user_already_exists} = ExBanking.create_user(account)
    end

    test "error on incorrect args" do
      assert {:error, :wrong_arguments} = ExBanking.create_user(123)
    end
  end

  describe "deposit/3" do
    setup do
      user = "user-deposit-1"
      [user: user, account: ExBanking.create_user(user)]
    end

    test "deposit", %{user: user} do
      assert {:ok, 10.0} = ExBanking.deposit(user, 10, "usd")
      assert {:ok, 10.13} = ExBanking.deposit(user, 0.125, "usd")
    end
  end

  describe "withdraw/3" do
    setup do
      user = "user-withdraw-1"
      :ok = ExBanking.create_user(user)
      [user: user]
    end

    test "withdraw", %{user: user} do
      assert {:ok, 10.0} = ExBanking.deposit(user, 10, "usd")
      assert {:ok, 5.0} = ExBanking.withdraw(user, 5, "usd")
    end
  end

  describe "get_balance/2" do
    test "get currency balance" do
      user = "user-bal-1"
      :ok = ExBanking.create_user(user)

      assert {:ok, 0.0} = ExBanking.get_balance(user, "usd")
      assert {:ok, 10.0} = ExBanking.deposit(user, 10, "euro")
      assert {:ok, 10.0} = ExBanking.get_balance(user, "euro")
    end
  end

  describe "send/4" do
    setup do
      user_a = "user-a"
      user_b = "user-b"
      :ok = ExBanking.create_user(user_a)
      :ok = ExBanking.create_user(user_b)
      [user1: user_a, user2: user_b]
    end

    test "send money", %{user1: user1, user2: user2} do
      assert {:ok, 10.0} = ExBanking.deposit(user1, 10, "usd")
      assert {:ok, 5.5, 4.5} = ExBanking.send(user1, user2, 4.5, "usd")
    end
  end
end
