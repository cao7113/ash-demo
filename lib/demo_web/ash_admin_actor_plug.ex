defmodule DemoWeb.AshAdminActorPlug do
  # https://ash-admin.hexdocs.pm/getting-started-with-ash-admin.html#security
  # built-in plug https://github.com/ash-project/ash_admin/blob/v1.3.2/lib/ash_admin/actor_plug/plug.ex

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
