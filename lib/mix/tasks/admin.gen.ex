defmodule Mix.Tasks.Admin.Gen do
  @moduledoc """
  Promotes an existing user to admin after an exact phrase confirmation.

  Usage:

      mix admin.gen --email user@example.com
  """

  use Mix.Task

  @shortdoc "Promotes an existing user to admin"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    {options, positional_args} =
      OptionParser.parse!(args,
        strict: [email: :string],
        aliases: [e: :email]
      )

    if positional_args != [] do
      Mix.raise("Usage: mix admin.gen --email EMAIL")
    end

    email = required_option(options, :email, "EMAIL")
    confirmation = Demo.Accounts.admin_upgrade_confirmation(email)

    confirmed? =
      case Mix.shell().prompt("Type \"#{confirmation}\" to continue: ") do
        response when is_binary(response) -> String.trim(response) == confirmation
        _ -> false
      end

    if confirmed? do
      case Demo.Accounts.promote_to_admin(email, confirmation) do
        {:ok, user} ->
          Mix.shell().info("User upgraded to admin: #{user.email}")

        {:error, :user_not_found} ->
          Mix.raise("No user found with email #{email}")

        {:error, :already_admin} ->
          Mix.raise("The user is already an admin")

        {:error, :confirmation_mismatch} ->
          Mix.raise("Admin upgrade confirmation did not match; upgrade cancelled")

        {:error, error} ->
          Mix.raise("Could not upgrade user: #{Exception.message(error)}")
      end
    else
      Mix.raise("Admin upgrade confirmation did not match; upgrade cancelled")
    end
  end

  defp required_option(options, key, label) do
    case Keyword.get(options, key) do
      value when is_binary(value) and value != "" -> value
      _ -> Mix.raise("#{label} is required")
    end
  end
end
