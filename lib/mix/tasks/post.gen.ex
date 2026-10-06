defmodule Mix.Tasks.Post.Gen do
  @moduledoc """
    Generates a specified number of blog posts.

    Usage:

      mix post.gen
      mix post.gen --count 20
      mix post.gen -c 20
  """

  use Mix.Task

  @shortdoc "Generates blog posts"

  # https://mix.hexdocs.pm/1.20.4/Mix.Task.html#module-requirements
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    {options, positional_args} =
      OptionParser.parse!(args,
        strict: [count: :integer],
        aliases: [c: :count]
      )

    if positional_args != [] do
      Mix.raise("Usage: mix post.gen [--count COUNT]")
    end

    count = options |> Keyword.get(:count, 10) |> validate_count()

    if count > 0 do
      Enum.each(1..count, &create_post/1)
    end

    Mix.shell().info("Generated #{count} blog post(s).")
  end

  defp validate_count(count) when count >= 0, do: count

  defp validate_count(_count) do
    Mix.raise("COUNT must be a non-negative integer")
  end

  defp create_post(index) do
    Demo.Blog.Post
    |> Ash.Changeset.for_create(:create, %{
      title: "Generated post #{index}",
      content: "This is generated blog post #{index}."
    })
    |> Ash.create!()
  end
end
