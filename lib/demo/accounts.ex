defmodule Demo.Accounts do
  use Ash.Domain, otp_app: :demo, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Demo.Accounts.User
    resource Demo.Accounts.Token
  end
end
