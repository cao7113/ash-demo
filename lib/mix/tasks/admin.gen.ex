defmodule Mix.Tasks.Admin.Gen do
  @moduledoc """
  Promotes an existing non-admin user after an exact phrase confirmation.
  Existing admins are reported without prompting.

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

    case Demo.Accounts.find_user(email) do
      {:ok, nil} ->
        Mix.raise("No user found with email #{email}")

      {:ok, %{role: :admin}} ->
        Mix.shell().info("The user is already an admin")

      {:ok, user} ->
        confirmation = Demo.Accounts.admin_upgrade_confirmation(email)

        confirmed? =
          case Mix.shell().prompt("Type \"#{confirmation}\" to continue: ") do
            response when is_binary(response) -> String.trim(response) == confirmation
            _ -> false
          end

        if confirmed? do
          upgrade_to_admin(user, confirmation)
        else
          Mix.raise("Admin upgrade confirmation did not match; upgrade cancelled")
        end

      {:error, error} ->
        Mix.raise("Could not find user: #{Exception.message(error)}")
    end
  end

  defp upgrade_to_admin(user, confirmation) do
    case Demo.Accounts.upgrade_to_admin(user, confirmation) do
      {:ok, user} ->
        Mix.shell().info("User upgraded to admin: #{user.email}")

      {:error, :already_admin} ->
        Mix.shell().info("The user is already an admin")

      {:error, {:confirmation_mismatch, reason}} ->
        Mix.raise("Admin upgrade confirmation did not match; upgrade cancelled: #{reason}")

      {:error, error} ->
        Mix.raise("Could not upgrade user: #{Exception.message(error)}")
    end
  end

  defp required_option(options, key, label) do
    case Keyword.get(options, key) do
      value when is_binary(value) and value != "" -> value
      _ -> Mix.raise("#{label} is required")
    end
  end
end
