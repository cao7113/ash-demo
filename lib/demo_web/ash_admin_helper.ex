defmodule DemoWeb.AshAdminHelper do
  import AshAdmin.Helpers, only: [admin_path: 2]

  @doc """
  根据 Ash Record 动态生成 AshAdmin 链接
  """
  def record_admin_path(record, prefix \\ "/admin", action_type \\ :read) do
    resource = record.__struct__

    # 提取 Domain & Resource 模块短名称
    domain_name = resource |> Ash.Resource.Info.domain() |> Module.split() |> List.last()
    resource_name = resource |> Module.split() |> List.last()

    # 提取 Primary Key 值
    primary_key_val =
      case Ash.Resource.Info.primary_key(resource) do
        [single_key] -> Map.get(record, single_key)
        keys -> Enum.map_join(keys, ",", &"#{&1}:#{Map.get(record, &1)}")
      end

    admin_path(prefix, %{
      domain: domain_name,
      resource: resource_name,
      primary_key: primary_key_val,
      action_type: action_type
    })
  end
end
