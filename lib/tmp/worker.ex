defmodule Tmp.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  defmodule State do
    @enforce_keys [:base_dir, :uid, :function]
    defstruct [:base_dir, :uid, :function]
  end

  @spec execute(binary, Path.t(), function, timeout) :: term()
  def execute(base_dir, uid, function, timeout) when is_binary(uid) and is_function(function) do
    state = %State{uid: uid, base_dir: base_dir, function: function}

    {:ok, pid} = start_link(state)

    GenServer.call(pid, :execute, timeout)
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{} = state) do
    Tmp.Cleaner.monitor({self(), dir_path(state)})

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:execute, _from, %State{function: function} = state) do
    path = dir_path(state)

    File.mkdir!(path)

    reply = function.(path)

    {:stop, :normal, reply, state}
  end

  defp dir_path(%State{base_dir: base_dir, uid: uid}) do
    Path.join(base_dir, uid)
  end
end
