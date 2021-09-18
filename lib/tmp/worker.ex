defmodule Tmp.Worker do
  @moduledoc """
  Executes the function given to `Tmp.dir/2` in a GenServer process
  """

  use GenServer, restart: :temporary

  defmodule State do
    @enforce_keys [:path, :function]
    defstruct [:path, :function]
  end

  @spec execute(Path.t(), function, timeout) :: term()
  def execute(path, function, timeout) when is_function(function, 1) do
    state = %State{path: path, function: function}

    {:ok, pid} = start_link(state)

    GenServer.call(pid, :execute, timeout)
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{path: path} = state) do
    Tmp.Monitor.monitor(path)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:execute, _from, %State{path: path, function: function} = state) do
    File.mkdir_p!(path)

    reply = function.(path)

    {:stop, :normal, reply, state}
  end
end
