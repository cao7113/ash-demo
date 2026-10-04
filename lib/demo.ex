defmodule Demo do
  @moduledoc """
  Demo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias Demo.Accounts

  def users do
    Ash.read!(Accounts.User, authorize?: false)
  end
end
