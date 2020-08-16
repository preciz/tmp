defmodule Tmp.Cleaner do
  @moduledoc false

  require Logger

  use GenServer

  def start_link(_ \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Process.flag(:trap_exit, true)

    {:ok, %{}}
  end

  def monitor({pid, dir}) when is_pid(pid) and is_binary(dir) do
    GenServer.cast(__MODULE__, {:monitor, {pid, dir}})
  end

  def handle_cast({:monitor, {pid, dir}}, state) do
    Process.monitor(pid)

    {:noreply, Map.put(state, pid, dir)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_state =
      case Map.get(state, pid) do
        dir when is_binary(dir) ->
          File.rm_rf!(dir)
          Map.delete(state, pid)

        nil ->
          state
      end

    {:noreply, new_state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def terminate(_reason, state) do
    state
    |> Enum.each(fn _pid, dir ->
      File.rm_rf!(dir)
    end)
  end
end
