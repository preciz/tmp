defmodule Tmp.Worker do
  @moduledoc """
  Executes the function given to `Tmp.dir/3` in a temporary GenServer process.
  This module is not typically used directly.

  This module is responsible for:
  - Creating a temporary directory
  - Ensuring the directory is monitored for cleanup
  """

  use GenServer, restart: :temporary

  defmodule State do
    @enforce_keys [:monitor, :path, :function]
    defstruct [:monitor, :path, :function]
  end

  @spec execute(GenServer.name(), Path.t(), function, timeout) :: term()
  def execute(monitor, path, function, timeout) when is_function(function, 1) do
    state = %State{monitor: monitor, path: path, function: function}

    {:ok, pid} = start_link(state)

    GenServer.call(pid, :execute, timeout)
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{monitor: monitor, path: path} = state) do
    Tmp.Monitor.monitor(monitor, path)
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:execute, _from, %State{path: path, function: function} = state) do
    File.mkdir_p!(path)

    reply = function.(path)

    {:stop, :normal, reply, state}
  end
end
