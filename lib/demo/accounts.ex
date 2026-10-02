defmodule Demo.Accounts do
  use Ash.Domain,
    otp_app: :demo

  resources do
    resource Demo.Accounts.Token
    resource Demo.Accounts.User
  end
end
