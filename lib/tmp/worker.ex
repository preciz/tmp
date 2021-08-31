defmodule Tmp.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  defmodule State do
    @enforce_keys [:path, :base_dir, :dirname, :function, :cleaner]
    defstruct [:path, :base_dir, :dirname, :function, :cleaner]
  end

  @spec execute(binary, Path.t(), function, timeout, atom) :: term()
  def execute(base_dir, dirname, function, timeout, cleaner)
      when is_binary(dirname) and is_function(function) and is_atom(cleaner) do
    state = %State{
      base_dir: base_dir,
      dirname: dirname,
      path: Path.join(base_dir, dirname),
      function: function,
      cleaner: cleaner
    }

    {:ok, pid} = start_link(state)

    GenServer.call(pid, :execute, timeout)
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{path: path, cleaner: cleaner} = state) do
    Tmp.Cleaner.monitor(self(), path, cleaner)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:execute, _from, %State{path: path, function: function} = state) do
    File.mkdir_p!(path)

    reply = function.(path)

    {:stop, :normal, reply, state}
  end
end
