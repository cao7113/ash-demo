defmodule DemoWeb.AdminActorPlug do
  @moduledoc false

  @spec set_actor_session(Plug.Conn.t()) :: Plug.Conn.t()
  def set_actor_session(conn), do: conn

  @spec actor_assigns(Phoenix.LiveView.Socket.t(), map()) :: keyword()
  def actor_assigns(socket, session) do
    [
      actor: socket.assigns[:current_user],
      actor_domain: Demo.Accounts,
      actor_resources: [{Demo.Accounts, Demo.Accounts.User}],
      actor_paused: false,
      actor_tenant: session["tenant"],
      authorizing: true,
      tenant: session["tenant"]
    ]
  end
end
