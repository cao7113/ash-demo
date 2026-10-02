defmodule Demo.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Demo.Accounts.User, _opts, _context) do
    Application.fetch_env(:demo, :token_signing_secret)
  end
end
