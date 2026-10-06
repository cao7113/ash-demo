defmodule Mix.Tasks.User.Gen do
  @moduledoc """
  Creates a regular user.

  Usage:

      mix user.gen --email user@example.com --password "password"
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
    password = required_option(options, :password, "PASSWORD")

    case Demo.Accounts.create_user(email, password) do
      {:ok, user} ->
        Mix.shell().info("User created: #{user.email}")

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
