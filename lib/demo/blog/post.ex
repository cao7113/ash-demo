defmodule Demo.Blog.Post do
  use Demo.Resource,
    otp_app: :demo,
    domain: Demo.Blog,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Resource]

  admin do
    form do
      field :title, type: :short_text
      field :content, type: :long_text
    end
  end

  postgres do
    table "posts"
    repo Demo.Repo
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true

      # https://ash.hexdocs.pm/dsl-ash-resource.html#actions-read-pagination
      pagination do
        default_limit 8
        offset? true
        keyset? true
        countable :by_default
      end
    end

    # read :another_read do
    #   filter fn query ->
    #     query
    #   end
    # end

    create :create do
      primary? true
      accept [:title, :content]
    end

    update :update do
      primary? true
      accept [:title, :content]
    end

    # create :test_create do
    #   accept [:title]
    # end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :content, :string do
      public? true
    end

    timestamps()
  end
end
