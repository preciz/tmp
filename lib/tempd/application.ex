defmodule Tempd.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Tempd.Cleaner,
      {DynamicSupervisor, strategy: :one_for_one, name: Tempd.DirSupervisor}
    ]

    opts = [strategy: :rest_for_one, name: Tempd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
