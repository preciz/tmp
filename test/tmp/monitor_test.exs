defmodule Tmp.MonitorTest do
  use ExUnit.Case

  defmodule TestTmp do
    use Tmp

    def terminate_monitor do
      Supervisor.terminate_child(__MODULE__, Tmp.Monitor)
    end
  end

  setup do
    start_supervised!({TestTmp, name: TestTmp})
    :ok
  end

  test "Deletes all monitored dirs with terminate/2 on crash" do
    pid = self()

    spawn(fn ->
      TestTmp.dir(fn dir ->
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

    TestTmp.terminate_monitor()

    # let Tmp.Monitor.terminate/2 finish
    Process.sleep(100)

    refute File.exists?(dir)
  end
end
