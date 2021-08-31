defmodule Tmp do
  @moduledoc """
  Temporary directories that are monitored and automatically removed.
  """

  @doc """
  Creates a temporary directory and passes the path to the given function.

  `function` runs in a new linked GenServer process.
  The directory is automatically removed when the function returns or the
  process terminates.

  ## Options

    * `:base_dir` - The directory where `:dirname` is going to be created.
      Defaults to `System.tmp_dir()`.  To customize the default `:base_dir`
      use config: `config :tmp, :default_base_dir, "my_dir"`

    * `:prefix` - Prefix the directory name

    * `:timeout` - How long the function is allowed to run before the
      GenServer call terminates, defaults to :infinity

    * `:cleaner` - The name of the `Tmp.Cleaner` GenServer. Defaults to
      `Tmp.Cleaner`


  ## Examples

      iex> Tmp.dir(fn tmp_dir_path ->
      ...>   Path.join(tmp_dir_path, "my_new_file") |> File.touch()
      ...>   1 + 1
      ...> end)
      2

  """
  @spec dir(function, list) :: term()
  def dir(function, options \\ []) when is_function(function, 1) or is_function(function, 2) do
    base_dir = Keyword.get(options, :base_dir, default_base_dir())
    prefix = Keyword.get(options, :prefix)
    timeout = Keyword.get(options, :timeout, :infinity)
    cleaner = Keyword.get(options, :cleaner, Tmp.Cleaner)
    dirname = dirname(prefix)

    Tmp.Worker.execute(base_dir, dirname, function, timeout, cleaner)
  end

  defp dirname(_prefix = nil), do: rand_dirname()
  defp dirname(prefix), do: prefix <> "-" <> rand_dirname()

  defp rand_dirname do
    sec = :os.system_time(:second) |> Integer.to_string()
    rand = :crypto.strong_rand_bytes(5) |> Base.encode16(case: :lower)

    sec <> "-" <> rand
  end

  defp default_base_dir do
    Application.get_env(:tmp, :default_base_dir) || System.tmp_dir()
  end
end
