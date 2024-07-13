defmodule Tmp.LoadTest do
  use ExUnit.Case, async: true

  defmodule TestTmp do
    use Tmp
  end

  @job_count 10_000

  setup do
    start_supervised!({TestTmp, name: TestTmp})
    :ok
  end

  test "handles #{@job_count} concurrent jobs" do
    task_results =
      Task.async_stream(
        1..@job_count,
        fn _ ->
          TestTmp.dir(
            fn tmp_dir ->
              # Verify that the temporary directory has the correct prefix
              assert Path.basename(tmp_dir) =~ ~r/^load_test-\d+-[a-f0-9]+$/
              file_path = Path.join(tmp_dir, "test_file")
              File.write!(file_path, "test content")
              assert File.read!(file_path) == "test content"
              :ok
            end,
            prefix: "load_test"
          )
        end,
        max_concurrency: System.schedulers_online() * 2,
        timeout: :infinity
      )
      |> Enum.to_list()

    assert Enum.count(task_results) == @job_count
    assert Enum.all?(task_results, &match?({:ok, :ok}, &1))

    # Ensure all temporary directories are cleaned up
    Process.sleep(1000)
    assert Path.wildcard(Path.join(System.tmp_dir(), "load_test-*")) == []
  end
end
