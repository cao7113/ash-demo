defmodule Mix.Tasks.User.Gen do
  @moduledoc """
  Creates a regular user.

  Usage:

      mix user.gen --email/-e user@example.com --password/-p "password"
  """

  use Mix.Task

  @shortdoc "Generates a user"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    {options, positional_args} =
      OptionParser.parse!(args,
        strict: [email: :string, password: :string],
        aliases: [e: :email, p: :password]
      )

    if positional_args != [] do
      Mix.raise("Usage: mix user.gen --email EMAIL --password PASSWORD")
    end

    email = required_option(options, :email, "EMAIL")
    password = Keyword.get(options, :password, "password")

    case Demo.Accounts.create_user(email, password) do
      {:ok, user} ->
        Mix.shell().info("User created: #{user.email}")

      {:error, :already_exists} ->
        Mix.raise("A user with email #{email} already exists")

      {:error, error} ->
        Mix.raise("Could not create user: #{Exception.message(error)}")
    end
  end

  defp required_option(options, key, label) do
    case Keyword.get(options, key) do
      value when is_binary(value) and value != "" -> value
      _ -> Mix.raise("#{label} is required")
    end
  end
end
