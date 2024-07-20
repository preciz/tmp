defmodule Tmp do
  @moduledoc """
  Temporary directories that are monitored and automatically removed.

  ## Usage

  Define your Tmp module:

      defmodule MyApp.Tmp do
        use Tmp
      end

  Or with a custom base directory:

      defmodule MyApp.CustomTmp do
        use Tmp, base_dir: "/path/to/custom/base/dir"
      end

  Add it to your supervision tree:

      children = [
        {MyApp.Tmp, name: MyApp.Tmp}
      ]

  Use it in your code:

      MyApp.Tmp.dir(fn tmp_dir_path ->
        _my_file_path = Path.join(tmp_dir_path, "my_file")
        # do work with my_file_path...
        # then return a value
        {:ok, :foobar}
      end)

  You can also override the base directory for a specific call:

      MyApp.Tmp.dir(fn tmp_dir_path ->
        # ...
      end, base_dir: "/path/to/another/base/dir")
  """

  defmacro __using__(opts) do
    quote do
      use Supervisor

      @base_dir unquote(Keyword.get(opts, :base_dir))

      def start_link(opts) do
        Supervisor.start_link(__MODULE__, opts, name: opts[:name])
      end

      @impl true
      def init(opts) do
        children = [
          {Tmp.Monitor, name: Module.concat(__MODULE__, Monitor)}
        ]

        Supervisor.init(children, strategy: :one_for_one)
      end

      def dir(function, options \\ []) when is_function(function, 1) do
        options = Keyword.put_new(options, :base_dir, @base_dir)
        Tmp.dir(__MODULE__, function, options)
      end
    end
  end

  @doc """
  Creates a temporary directory and passes the path to the given function.

  `function` runs in a new linked GenServer process.
  The directory is automatically removed when the function returns or the
  process terminates.

  ## Options

    * `:base_dir` - The directory where the temporary directory will be created.
      Defaults to `System.tmp_dir()`. This directory serves as the parent
      directory and won't be removed when the function returns. Only the
      newly created temporary directory within `:base_dir` will be cleaned up.

    * `:prefix` - A string to prefix the temporary directory name. This can be
      useful for identifying the purpose or origin of the temporary directory.

    * `:timeout` - How long the function is allowed to run before the
      GenServer call terminates, defaults to :infinity

  ## Examples

      MyApp.Tmp.dir(fn tmp_dir_path ->
        :ok = Path.join(tmp_dir_path, "my_new_file") |> File.touch()
        1 + 1
      end)
  """
  @spec dir(module(), function(), keyword()) :: term()
  def dir(module, function, options \\ []) when is_function(function, 1) do
    base_dir = Keyword.get(options, :base_dir) || System.tmp_dir()
    prefix = Keyword.get(options, :prefix)
    timeout = Keyword.get(options, :timeout, :infinity)
    dirname = dirname(prefix)
    path = Path.join(base_dir, dirname)

    monitor = Module.concat(module, Monitor)
    Tmp.Worker.execute(monitor, path, function, timeout)
  end

  @doc false
  def dirname(_prefix = nil), do: rand_dirname()
  def dirname(prefix), do: prefix <> "-" <> rand_dirname()

  @doc false
  def rand_dirname do
    sec = :os.system_time(:second) |> Integer.to_string()
    rand = :crypto.strong_rand_bytes(5) |> Base.encode16(case: :lower)

    sec <> "-" <> rand
  end
end
