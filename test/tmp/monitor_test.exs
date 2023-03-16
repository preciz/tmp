defmodule Tmp.MonitorTest do
  use ExUnit.Case

  test "Deletes all monitored dirs with terminate/2 on crash" do
    pid = self()

    spawn(fn ->
      Tmp.dir(fn dir ->
        send(pid, {:tmp_dir, dir})
        Process.sleep(:infinity)
      end)
    end)

    dir =
      receive do
        {:tmp_dir, dir} -> dir
      end

    assert File.exists?(dir)

    # let Tmp.Monitor state update
    Process.sleep(100)

    Supervisor.terminate_child(Tmp.Application, Tmp.Monitor)

    # let Tmp.Monitor.terminate/2 finish
    Process.sleep(100)

    refute File.exists?(dir)
  end
end
