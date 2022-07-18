defmodule ExBanking.GenAccountTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExBanking.GenAccount

  describe "deposit" do
    setup do
      user = :"user-d-1"
      :ok = ExBanking.create_user(user)
      [user: user]
    end

    test "deposit", %{user: user} do
      assert {:ok, 10} = GenAccount.deposit(user, 10, "usd")
      assert {:ok, 10.1250} = GenAccount.deposit(user, 0.125, "usd")
    end
  end

  describe "withdraw" do
    setup do
      user = :"user-w-1"
      :ok = ExBanking.create_user(user)
      [user: user]
    end

    test "withdraw balance", %{user: user} do
      assert {:ok, 10} = GenAccount.deposit(user, 10, "usd")
      assert {:ok, 5} = GenAccount.withdraw(user, 5, "usd")
    end
  end
end
