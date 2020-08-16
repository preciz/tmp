defmodule Tmp do
  @moduledoc """
  Temporary directories that are monitored and automatically removed.
  """

  @default_base_dir Application.get_env(:tmp, :default_base_dir) || System.tmp_dir()

  @doc """
  Creates a temporary directory and passes the path to the given function.
  The function runs in a new linked GenServer process.
  The directory is automatically removed when the function returns or the
  process terminates.

  ## Examples

      iex> Tmp.dir(fn _tmp_dir_path -> 1 + 1 end)
      2

  """
  @spec dir(function, list) :: term()
  def dir(function, options \\ []) when is_function(function) do
    timeout = Keyword.get(options, :timeout, :infinity)
    base_dir = Keyword.get(options, :base_dir, @default_base_dir)

    uid = random_uid()

    Tmp.Worker.execute(base_dir, uid, function, timeout)
  end

  defp random_uid do
    :crypto.strong_rand_bytes(10) |> Base.encode16(case: :lower)
  end
end
