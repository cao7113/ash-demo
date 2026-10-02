defmodule DemoWeb.AdminLayouts do
  use DemoWeb, :html

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" phx-socket={live_socket_path(@conn)}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <title>Ash Admin</title>
        <style>
          <%= raw(AshAdmin.Layouts.render("app.css", %{})) %>
        </style>
      </head>
      <body class="bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 h-screen overflow-hidden pt-14">
        <header class="fixed inset-x-0 top-0 z-50 h-14 border-b border-slate-200 bg-white dark:border-slate-700/50 dark:bg-slate-900">
          <div class="flex h-full items-center justify-end gap-3 px-4 sm:px-6">
            <div class="flex min-w-0 items-center gap-2.5 border-l border-slate-200 pl-3 dark:border-slate-700">
              <.icon name="hero-user-circle" class="h-6 w-6 shrink-0 text-slate-400" />
              <div class="min-w-0 leading-tight">
                <div class="text-[10px] font-semibold uppercase tracking-wider text-slate-400">
                  Signed in as
                </div>
                <div class="max-w-[min(40vw,16rem)] truncate text-sm font-medium text-slate-700 dark:text-slate-200">
                  {@conn.assigns[:current_user].email}
                </div>
              </div>
            </div>
            <.link
              href={~p"/sign-out"}
              aria-label="Sign out"
              title="Sign out"
              class="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-md text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-800 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-100"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" />
            </.link>
          </div>
        </header>

        {@inner_content}

        <script>
          <%= raw(AshAdmin.Layouts.render("app.js", %{})) %>
        </script>
      </body>
    </html>
    """
  end

  defp live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
  end
end
