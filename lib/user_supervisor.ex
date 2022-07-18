defmodule ExBanking.UserSupervisor do
  @moduledoc """
  Supervisor for user account processes
  """

  use DynamicSupervisor

  @doc """
  Starts the given job as a child process.
  """
  @spec start_child(child_specs :: any()) :: DynamicSupervisor.on_start_child()
  def start_child(child_specs) do
    DynamicSupervisor.start_child(__MODULE__, child_specs)
  end

  @spec start_link(keyword) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
