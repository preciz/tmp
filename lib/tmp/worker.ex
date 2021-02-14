defmodule Tmp.Worker do
  @moduledoc false

  use GenServer, restart: :temporary

  defmodule State do
    @enforce_keys [:path, :base_dir, :dirname, :function]
    defstruct [:path, :base_dir, :dirname, :function]
  end

  @spec execute(binary, Path.t(), function, timeout) :: term()
  def execute(base_dir, dirname, function, timeout)
      when is_binary(dirname) and is_function(function) do
    state = %State{
      base_dir: base_dir,
      dirname: dirname,
      path: Path.join(base_dir, dirname),
      function: function
    }

    {:ok, pid} = start_link(state)

    GenServer.call(pid, :execute, timeout)
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{path: path} = state) do
    Tmp.Cleaner.monitor(self(), path)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:execute, _from, %State{path: path, function: function} = state) do
    File.mkdir_p!(path)

    reply =
      case function do
        function when is_function(function, 1) ->
          function.(path)

        function when is_function(function, 2) ->
          keep = fn -> Tmp.Cleaner.demonitor(self()) end

          function.(path, keep)
      end

    {:stop, :normal, reply, state}
  end
end
