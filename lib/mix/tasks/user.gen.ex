defmodule Mix.Tasks.User.Gen do
  @moduledoc """
  Creates a user, optionally with administrator privileges.

  The password is validated and hashed by the `:register_with_password` Ash action.

  Options:

    * `-e`, `--email` - required user email
    * `-p`, `--password` - required password
    * `-a`, `--admin` - create an administrator or upgrade an existing user

  When `--admin` is used for an existing user, the task asks for confirmation
  and verifies the supplied password before changing the user's role. Existing
  users are never overwritten.

  Usage:

      mix user.gen --email user@example.com --password "password"
      mix user.gen -e user@example.com -p "password" --admin
      mix user.gen -e admin@example.com -p "password" -a
  """

  use Mix.Task

  @shortdoc "Generates a user"

  @impl Mix.Task
  def run(args) do
    {options, positional_args} =
      OptionParser.parse!(args,
        strict: [admin: :boolean, email: :string, password: :string],
        aliases: [a: :admin, e: :email, p: :password]
      )

    if positional_args != [] do
      Mix.raise("Usage: mix user.gen --email EMAIL --password PASSWORD [--admin]")
    end

    email = required_option(options, :email, "EMAIL")
    password = required_option(options, :password, "PASSWORD")
    admin? = Keyword.get(options, :admin, false)

    Mix.Task.run("app.start")

    case find_user(email) do
      {:ok, nil} ->
        create_user(email, password, admin?)

      {:ok, user} when admin? ->
        upgrade_existing_user(user, password)

      {:ok, _user} ->
        Mix.raise("A user with email #{email} already exists")

      {:error, error} ->
        Mix.raise("Could not check existing user: #{Exception.message(error)}")
    end
  end

  defp create_user(email, password, admin?) do
    changeset =
      Demo.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: email,
        password: password,
        password_confirmation: password
      })
      |> Ash.Changeset.change_attribute(:role, if(admin?, do: :admin, else: :user))
      |> maybe_confirm_admin(admin?)

    case Ash.create(changeset, domain: Demo.Accounts, authorize?: false) do
      {:ok, user} ->
        Mix.shell().info("#{if admin?, do: "Admin", else: "User"} created: #{user.email}")

      {:error, error} ->
        Mix.raise("Could not create user: #{Exception.message(error)}")
    end
  end

  defp find_user(email) do
    query = Ash.Query.for_read(Demo.Accounts.User, :get_by_email, %{email: email})

    Ash.read_one(query, domain: Demo.Accounts, authorize?: false)
  end

  defp upgrade_existing_user(%{role: :admin}, _password) do
    Mix.raise("The user is already an admin")
  end

  defp upgrade_existing_user(user, password) do
    if Mix.shell().yes?("User #{user.email} exists. Upgrade this user to admin?") do
      verify_password!(user.email, password)

      case Ash.update(user, %{role: :admin},
             action: :set_role,
             domain: Demo.Accounts,
             authorize?: false
           ) do
        {:ok, _user} ->
          Mix.shell().info("User upgraded to admin: #{user.email}")

        {:error, error} ->
          Mix.raise("Could not upgrade user: #{Exception.message(error)}")
      end
    else
      Mix.raise("Admin upgrade cancelled")
    end
  end

  defp verify_password!(email, password) do
    query =
      Ash.Query.for_read(Demo.Accounts.User, :sign_in_with_password, %{
        email: email,
        password: password
      })

    case Ash.read_one(query, domain: Demo.Accounts, authorize?: false) do
      {:ok, nil} ->
        Mix.raise("Password verification failed")

      {:ok, _user} ->
        :ok

      {:error, _error} ->
        Mix.raise("Password verification failed")
    end
  end

  defp maybe_confirm_admin(changeset, true),
    do: Ash.Changeset.change_attribute(changeset, :confirmed_at, DateTime.utc_now())

  defp maybe_confirm_admin(changeset, false), do: changeset

  defp required_option(options, key, label) do
    case Keyword.get(options, key) do
      value when is_binary(value) and value != "" -> value
      _ -> Mix.raise("#{label} is required")
    end
  end
end
