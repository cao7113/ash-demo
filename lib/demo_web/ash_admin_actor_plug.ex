defmodule DemoWeb.AshAdminActorPlug do
  # https://ash-admin.hexdocs.pm/getting-started-with-ash-admin.html#security

  @moduledoc false
  @behaviour AshAdmin.ActorPlug

  @doc false
  @impl true
  def actor_assigns(socket, session) do
    dispatcher = socket.assigns[:current_user]

    [
      actor: dispatcher,
      actor_domain: Demo.Accounts,
      actor_resources: [{Demo.Accounts, Demo.Accounts.User}],
      actor_paused: false,
      authorizing: true,
      actor_tenant: session["tenant"],
      tenant: session["tenant"]
    ]
  end

  @doc false
  @impl true
  def set_actor_session(conn), do: conn
end
