defmodule Tmp.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Tmp.Cleaner
    ]

    opts = [strategy: :one_for_one, name: Tmp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
