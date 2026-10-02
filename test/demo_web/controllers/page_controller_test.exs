defmodule DemoWeb.PageControllerTest do
  use DemoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end

  test "GET /admin redirects unauthenticated users to sign in", %{conn: conn} do
    conn = get(conn, "/admin")

    assert redirected_to(conn) == "/sign-in"
  end
end
