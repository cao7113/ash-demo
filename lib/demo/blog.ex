defmodule Demo.Blog do
  use Ash.Domain, otp_app: :demo, extensions: [AshAdmin.Domain]

  resources do
    resource(Demo.Blog.Post)
  end

  admin do
    show?(true)
  end
end
