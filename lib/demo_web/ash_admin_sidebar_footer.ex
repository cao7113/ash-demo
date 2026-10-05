defmodule Demo.AdminSidebarFooter do
  use Phoenix.Component

  import DemoWeb.CoreComponents, only: [icon: 1]
  import DemoWeb.AshAdminHelper, only: [record_admin_path: 3]

  attr :current_user, :any, default: nil
  attr :prefix, :string, required: true
  attr :current_path, :string, default: nil
  attr :variant, :atom, required: true

  def user_panel(assigns) do
    ~H"""
    <div
      id={"admin-sidebar-footer-#{@variant}"}
      class="space-y-2 border-t border-slate-700 pt-3 text-sm"
    >
      <.link
        href={record_admin_path(@current_user, @prefix, :update)}
        class="flex min-w-0 items-center gap-2 font-semibold text-white"
      >
        <span class="truncate">
          {@current_user.email}
          <span class="font-normal text-slate-300">({@current_user.role})</span>
        </span>
      </.link>

      <.link
        href="/sign-out"
        method="delete"
        class="flex items-center gap-2 text-slate-400 hover:text-white"
      >
        <.icon name="hero-arrow-left-solid" class="size-4" /> Sign out
      </.link>
    </div>
    """
  end
end
