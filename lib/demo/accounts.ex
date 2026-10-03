defmodule Demo.Accounts do
  use Ash.Domain, otp_app: :demo, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Demo.Accounts.Token
    resource Demo.Accounts.User
  end
end
