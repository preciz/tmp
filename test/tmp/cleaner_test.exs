defmodule Tmp.CleanerTest do
  use ExUnit.Case, async: true

  test "Cleans up with terminate/2 callback on crash" do
    pid = self()

    {:ok, cleaner_pid} = Tmp.Cleaner.start_link(name: :test_crash)

    spawn(fn ->
      Tmp.dir(
        fn dir ->
          send(pid, {:tmp_dir, dir})
          Process.sleep(:infinity)
        end,
        cleaner: :test_crash
      )
    end)

    dir =
      receive do
        {:tmp_dir, dir} -> dir
      end

   assert File.exists?(dir)

    # let the cleaner state update
    Process.sleep(100)

    Process.exit(cleaner_pid, :normal)

    # let terminate/2 of the cleaner GenServer finish
    Process.sleep(100)

   refute File.exists?(dir)
  end
end
