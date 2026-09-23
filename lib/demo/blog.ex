defmodule Demo.Blog do
  use Ash.Domain, otp_app: :demo, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Demo.Blog.Post
  end
end
