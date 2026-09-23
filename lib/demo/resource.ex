defmodule Demo.Resource do
  # https://ash.hexdocs.pm/writing-extensions.html#base-resources
  defmacro __using__(opts) do
    quote do
      use Ash.Resource, unquote(opts)
    end
  end
end
