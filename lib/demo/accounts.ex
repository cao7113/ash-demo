defmodule Demo.Accounts do
  use Ash.Domain, otp_app: :demo, extensions: [AshAdmin.Domain]

  @doc """
  Creates a regular user using the password registration action.
  """
  def create_user(email, password) do
    changeset =
      Demo.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: email,
        password: password,
        password_confirmation: password
      })
      |> Ash.Changeset.change_attribute(:role, :user)

    Ash.create(changeset, domain: __MODULE__, authorize?: false)
  end

  @doc """
  Promotes an existing user to admin when the confirmation phrase matches.
  """
  def promote_to_admin(email, confirmation) do
    query = Ash.Query.for_read(Demo.Accounts.User, :get_by_email, %{email: email})

    case Ash.read_one(query, domain: __MODULE__, authorize?: false) do
      {:ok, nil} ->
        {:error, :user_not_found}

      {:ok, %{role: :admin}} ->
        {:error, :already_admin}

      {:ok, user} ->
        if confirmation == admin_upgrade_confirmation(email) do
          Ash.update(user, %{role: :admin},
            action: :set_role,
            domain: __MODULE__,
            authorize?: false
          )
        else
          {:error, :confirmation_mismatch}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Returns the exact confirmation phrase required to promote a user to admin.
  """
  def admin_upgrade_confirmation(email) do
    "Confirm #{email} as admin"
  end

  admin do
    show? true
  end

  resources do
    resource Demo.Accounts.User
    resource Demo.Accounts.Token
  end
end
