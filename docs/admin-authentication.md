# AshAdmin 管理员认证与授权

## 1. 背景

项目使用以下组件：

- `ash_authentication`：认证用户身份、密码、Magic Link、token 和 session。
- `ash_authentication_phoenix`：将 Ash 认证接入 Phoenix Controller、Plug 和 LiveView。
- `ash_admin`：提供 Ash 资源管理界面，挂载路径为 `/admin`。
- `Ash.Policy.Authorizer`：在 Ash 资源层执行授权策略。

最初的 `/admin` 只要求用户登录。由于普通用户也可以通过公开注册流程创建账号，因此“已登录”并不等于“管理员”。本方案将认证和授权分开处理：

1. AshAuthentication 判断用户是否登录。
2. 用户的 `role` 判断用户是否为管理员。
3. Ash Policy 作为资源访问的最终授权边界。
4. AshAdmin 使用当前登录用户作为 Ash actor。

## 2. 访问模型

| 用户状态 | 访问 `/admin` 的结果 |
| --- | --- |
| 未登录 | 跳转到 `/sign-in` |
| 已登录且 `role == :user` | 跳转到首页 `/` |
| 已登录且 `role == :admin` | 进入 AshAdmin 管理界面 |

管理员和普通用户使用同一个 `/sign-in` 登录入口。项目没有单独的管理员密码或管理员登录页，管理员身份由用户记录上的 `role` 属性决定。

## 3. 用户角色

`Demo.Accounts.User` 增加了角色属性：

```elixir
attribute :role, :atom do
  allow_nil? false
  default :user
  constraints one_of: [:user, :admin]
  public? true
end
```

数据库迁移在 `priv/repo/migrations/20261004002919_migrate_resources1_dev.exs` 中，为 `users` 表新增 `role` 列，并将数据库默认值设为 `"user"`。资源层的默认值仍然是 `:user`，并且公开注册 action `:register_with_password` 不接收 `role` 参数，因此用户不能通过注册表单把自己注册为管理员。

执行迁移：

```bash
mix ecto.migrate
```

## 4. `/admin` 路由保护

[DemoWeb.Router](../lib/demo_web/router.ex) 在 `/admin` 下直接挂载 AshAdmin，并通过 `AshAuthentication.Phoenix.LiveSession.opts/1` 传入权限校验：

```elixir
scope "/admin" do
  pipe_through :browser

  ash_admin "/",
            AshAuthentication.Phoenix.LiveSession.opts(
              on_mount: [{DemoWeb.LiveUserAuth, :admin_only}]
            )
end
```

这里的职责分工是：

- `AshAuthentication.Phoenix.LiveSession` 从 session 恢复 `current_user`。
- `DemoWeb.LiveUserAuth.on_mount(:admin_only, ...)` 检查 `current_user.role == :admin`。

管理员判断位于 [DemoWeb.LiveUserAuth](../lib/demo_web/live_user_auth.ex)。未登录用户跳转到 `/sign-in`，已登录但不是管理员的用户跳转到 `/`。

## 5. Ash Policy 授权

用户资源启用了 `Ash.Policy.Authorizer`，并定义了管理员策略：

```elixir
policy always() do
  authorize_if actor_attribute_equals(:role, :admin)
end
```

这意味着普通用户不能通过 Ash action 读取或修改受保护的用户资源。路由 hook 负责尽早阻止普通用户进入管理界面，Ash Policy 则负责保护资源层，即使调用绕过 Web 路由也不能获得管理员权限。

认证流程本身需要访问用户资源，因此保留了 AshAuthentication interaction bypass：

```elixir
bypass AshAuthentication.Checks.AshAuthenticationInteraction do
  authorize_if always()
end
```

该 bypass 只用于认证框架执行必要的认证交互，不代表普通用户拥有管理员权限。

## 6. AshAdmin actor 集成

AshAdmin 默认使用自己的 actor 选择器。仅在路由上检查管理员还不够，因为 AshAdmin 执行资源 action 时必须把正确的 actor 传给 Ash。

项目通过 [DemoWeb.AshAdminActorPlug](../lib/demo_web/ash_admin_actor_plug.ex) 覆盖 AshAdmin 的 actor plug，并在 [config/config.exs](../config/config.exs) 中注册：

```elixir
config :ash_admin, :actor_plug, DemoWeb.AshAdminActorPlug
```

该 plug 在 `actor_assigns/2` 中将认证后的 `current_user` 设为 AshAdmin 的 `actor`，并同时设置：

```elixir
actor_domain: Demo.Accounts,
actor_resources: [{Demo.Accounts, Demo.Accounts.User}],
authorizing: true
```

因此 AshAdmin 内部执行的 Ash 查询和 action 会使用当前登录管理员进行 policy 授权，而不是使用空 actor 或未认证 actor。

## 7. 首次创建管理员

迁移完成后，现有用户默认都是普通用户。项目提供 `user.gen` Mix task 创建用户或首个管理员：

```bash
mix user.gen --email user@example.com --password "at-least-8-characters"
mix user.gen -e admin@example.com -p "at-least-8-characters" --admin
mix user.gen -e admin@example.com -p "at-least-8-characters" -a
```

该 task：

- 复用 `:register_with_password` action，确保密码使用现有 AshAuthentication 逻辑哈希。
- 默认创建 `:user` 用户；传入 `--admin` 或 `-a` 时设置角色为 `:admin`。
- 管理员会设置 `confirmed_at`，无需等待邮箱确认即可登录；普通用户继续走正常确认流程。
- 不会把 `role` 作为公开注册参数暴露。
- 如果邮箱已存在且未传 `--admin`，task 会直接失败。
- 如果邮箱已存在且传入 `--admin`，task 会先询问是否升级；确认后使用输入的密码验证现有用户，验证成功才升级角色，不会修改已有密码。
- 用户已经是管理员时，task 会直接提示，无需重复升级。

如果需要提升已有用户，也可以使用 Ash API：

```elixir
user =
  Demo.Accounts.User
  |> Ash.Query.for_read(:get_by_email, %{email: "admin@example.com"})
  |> Ash.read_one!(domain: Demo.Accounts, authorize?: false)

Ash.update!(user, %{role: :admin},
  action: :set_role,
  domain: Demo.Accounts,
  authorize?: false
)
```

可以在 IEx 中执行：

```bash
iex -S mix
```

`Demo.Accounts.User` 的 `:set_role` 是资源 action，而不是公开注册参数。正常管理员在 AshAdmin 中修改角色时仍会经过 `Ash.Policy.Authorizer`；只有首次初始化管理员时，运维命令才需要使用 `authorize?: false`。

## 8. 安全边界

- 不要在公开注册表单中暴露管理员角色选项。
- 新用户必须默认是 `:user`。
- 不要只依赖 `/admin` 路由拦截；资源 policy 才是最终授权边界。
- 只有受信任的初始化脚本或已有管理员可以执行 `:set_role`。
- 生产环境应通过安全的运维流程创建首个管理员，避免把管理员密码硬编码到仓库。
- 如果未来角色数量扩大，建议将简单的 `role` 字段演进为角色关系或 RBAC 方案，但仍由 Ash Policy 统一授权。

## 9. 验证

已验证：

```bash
mix compile --warnings-as-errors
mix format --check-formatted
mix test test/demo_web/controllers/page_controller_test.exs:9
```

其中 `/admin` 未登录访问测试确认会跳转到 `/sign-in`。仓库原有首页测试仍依赖旧的 Phoenix 默认文案，与本次管理员认证改动无关。
