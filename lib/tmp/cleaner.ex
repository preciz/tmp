defmodule Tmp.Cleaner do
  @moduledoc false

  require Logger

  use GenServer

  def monitor(pid, dir) when is_pid(pid) and is_binary(dir) do
    GenServer.cast(__MODULE__, {:monitor, {pid, dir}})
  end

  def demonitor(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:demonitor, pid})
  end

  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init([]) do
    Process.flag(:trap_exit, true)

    {:ok, %{}}
  end

  @impl GenServer
  def handle_cast({:monitor, {pid, dir}}, state) do
    monitor_ref = Process.monitor(pid)

    {:noreply, Map.put(state, pid, {monitor_ref, dir})}
  end

  @impl GenServer
  def handle_call({:demonitor, pid}, _from, state) do
    {val, new_state} = Map.pop(state, pid)

    with {monitor_ref, _dir} <- val do
      Process.demonitor(monitor_ref)
    end

    {:reply, :ok, new_state}
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
    |> Enum.each(fn _pid, dir ->
      File.rm_rf!(dir)
    end)
  end
end
