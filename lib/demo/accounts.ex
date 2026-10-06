defmodule Demo.Accounts do
  use Ash.Domain, otp_app: :demo, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Demo.Accounts.User
    resource Demo.Accounts.Token
  end

  ## User helpers

  alias Demo.Accounts.User

  def list_users do
    Ash.read!(User, domain: __MODULE__, authorize?: false, action: :read)
  end

  @doc """
  Finds a user by email.
  """
  def find_user(email) do
    query = Ash.Query.for_read(User, :get_by_email, %{email: email})

    Ash.read_one(query, domain: __MODULE__, authorize?: false)
  end

  @doc """
  Creates a regular user using the password registration action.

  Checks for an existing user with the same email by default. Pass
  `check_existing?: false` to skip that lookup.
  """
  def create_user(email, password, opts \\ []) do
    case Keyword.get(opts, :check_existing?, true) do
      true ->
        case find_user(email) do
          {:ok, nil} -> do_create_user(email, password)
          {:ok, _user} -> {:error, :already_exists}
          {:error, error} -> {:error, error}
        end

      false ->
        do_create_user(email, password)

      option_value ->
        {:error, {:invalid_option, :check_existing?, option_value}}
    end
  end

  defp do_create_user(email, password) do
    User
    |> Ash.Changeset.for_create(:register_with_password, %{
      email: email,
      password: password,
      password_confirmation: password
    })
    |> Ash.create(domain: __MODULE__, authorize?: false)
  end

  @doc """
  Promotes an existing user to admin when the confirmation phrase matches.

  Returns `{:error, :already_admin}` without requiring confirmation when the
  user already has the admin role. Accepts an email or an already-fetched user
  record to avoid an additional lookup.
  """
  def upgrade_to_admin(user_or_email, confirmation \\ nil)

  def upgrade_to_admin(%User{} = user, confirmation) do
    upgrade_user_to_admin(user, confirmation)
  end

  def upgrade_to_admin(email, confirmation) when is_binary(email) do
    case find_user(email) do
      {:ok, nil} ->
        {:error, :user_not_found}

      {:ok, user} ->
        upgrade_user_to_admin(user, confirmation)

      {:error, error} ->
        {:error, error}
    end
  end

  defp upgrade_user_to_admin(%{role: :admin}, _confirmation), do: {:error, :already_admin}

  defp upgrade_user_to_admin(user, confirmation) do
    want_confirmation = admin_upgrade_confirmation(user.email)

    if confirmation == want_confirmation do
      Ash.update(user, %{role: :admin},
        action: :set_role,
        domain: __MODULE__,
        actor: user,
        authorize?: false
      )
    else
      {:error, {:confirmation_mismatch, "Want: #{want_confirmation}, got: #{confirmation}"}}
    end
  end

  @doc """
  Returns the exact confirmation phrase required to promote a user to admin.
  """
  def admin_upgrade_confirmation(email) do
    "Confirm #{email} as admin"
  end
end
