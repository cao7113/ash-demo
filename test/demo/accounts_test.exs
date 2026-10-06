defmodule Demo.AccountsTest do
  use Demo.DataCase, async: false

  describe "create_user/3" do
    test "returns already_exists when the email is already registered" do
      email = "duplicate@example.com"

      assert {:ok, user} = Demo.Accounts.create_user(email, "password123")
      assert {:ok, found_user} = Demo.Accounts.find_user(email)
      assert found_user.id == user.id
      assert {:error, :already_exists} = Demo.Accounts.create_user(email, "password123")
    end
  end

  describe "find_user/1" do
    test "returns nil when no user has the email" do
      assert {:ok, nil} = Demo.Accounts.find_user("missing@example.com")
    end
  end

  describe "upgrade_to_admin/2" do
    test "upgrades an existing user after confirmation" do
      email = "promote@example.com"
      confirmation = Demo.Accounts.admin_upgrade_confirmation(email)

      assert {:ok, _user} = Demo.Accounts.create_user(email, "password123")
      assert {:ok, %{role: :admin}} = Demo.Accounts.upgrade_to_admin(email, confirmation)
    end

    test "does not require confirmation when the user is already an admin" do
      email = "already-admin@example.com"
      confirmation = Demo.Accounts.admin_upgrade_confirmation(email)

      assert {:ok, _user} = Demo.Accounts.create_user(email, "password123")
      assert {:ok, %{role: :admin}} = Demo.Accounts.upgrade_to_admin(email, confirmation)
      assert {:error, :already_admin} = Demo.Accounts.upgrade_to_admin(email)
    end

    test "upgrades an already-fetched user without looking it up again" do
      email = "fetched-user@example.com"
      confirmation = Demo.Accounts.admin_upgrade_confirmation(email)

      assert {:ok, _user} = Demo.Accounts.create_user(email, "password123")
      assert {:ok, user} = Demo.Accounts.find_user(email)
      assert {:ok, %{role: :admin}} = Demo.Accounts.upgrade_to_admin(user, confirmation)
    end
  end
end
