defmodule Tempd.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  defmodule State do
    @enforce_keys [:base_dir, :uid, :function]
    defstruct [:base_dir, :uid, :function]
  end

  @spec execute(binary, Path.t(), function, timeout) :: term()
  def execute(base_dir, uid, function, timeout) when is_binary(uid) and is_function(function) do
    state = %State{uid: uid, base_dir: base_dir, function: function}

    {:ok, pid} = DynamicSupervisor.start_child(Tempd.DirSupervisor, {__MODULE__, [state]})

    GenServer.call(pid, :execute, timeout)
  end

  def start_link([%State{base_dir: base_dir, uid: uid, function: function} = state])
      when is_binary(base_dir) and is_binary(uid) and is_function(function) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{} = state) do
    Tempd.Cleaner.monitor({self(), dir_path(state)})

    {:ok, state, {:continue, :create_dir}}
  end

  @impl GenServer
  def handle_continue(:create_dir, state) do
    File.mkdir_p!(dir_path(state))

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:execute, _from, %State{function: function} = state) do
    reply = function.(dir_path(state))

    {:stop, :normal, reply, state}
  end

  defp dir_path(%State{base_dir: base_dir, uid: uid}) do
    Path.join(base_dir, uid)
  end
end
