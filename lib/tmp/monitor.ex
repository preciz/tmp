defmodule Tmp.Monitor do
  @moduledoc """
  Monitors `Tmp.Worker` processes and removes
  their directories on exits.
  """
  use GenServer

  def monitor(monitor, dir, pid \\ self()) when is_binary(dir) and is_pid(pid) do
    GenServer.cast(monitor, {:monitor, {dir, pid}})
  end

  def start_link(options) do
    name = Keyword.fetch!(options, :name)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @impl GenServer
  def init([]) do
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  @impl GenServer
  def handle_cast({:monitor, {dir, pid}}, state) do
    monitor_ref = Process.monitor(pid)
    {:noreply, Map.put(state, pid, {monitor_ref, dir})}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {val, new_state} = Map.pop(state, pid)

    with {_monitor_ref, dir} <- val do
      File.rm_rf!(dir)
    end

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(_, state) do
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    state
    |> Enum.each(fn {_pid, {_monitor_ref, dir}} ->
      File.rm_rf(dir)
    end)
  end
end
