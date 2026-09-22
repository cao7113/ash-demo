# Follow Get Started Guide

- https://ash.hexdocs.pm/get-started.html#create-a-new-project

```
Helpdesk.Support.Ticket
|> Ash.Changeset.for_create(:open, %{subject: "My mouse won't click!"})
|> Ash.create!()

# parenthesis so you can paste into iex
ticket = (
  Helpdesk.Support.Ticket
  |> Ash.Changeset.for_create(:open, %{subject: "My mouse won't click!"})
  |> Ash.create!()
)

ticket = (
  ticket
  |> Ash.Changeset.for_update(:close)
  |> Ash.update!()
)

Ash.read!(Helpdesk.Support.Ticket)
```

## `Ash.DataLayer.Simple` when no data-layer configured

Resources without a data layer will implicitly be using Ash.DataLayer.Simple. This data is not persisted anywhere, and must be provided when running queries. It provides a utility for just this purpose, Ash.DataLayer.Simple.set_data/2.

```
# Ash.Query is a macro, so it must be required
require Ash.Query

tickets =
  for i <- 0..5 do
    ticket =
      Helpdesk.Support.Ticket
      |> Ash.Changeset.for_create(:open, %{subject: "Issue #{i}"})
      |> Ash.create!()

    if rem(i, 2) == 0 do
      ticket
      |> Ash.Changeset.for_update(:close)
      |> Ash.update!()
    else
      ticket
    end
  end


Helpdesk.Support.Ticket
|> Ash.Query.filter(contains(subject, "2"))
|> Ash.DataLayer.Simple.set_data(tickets)
|> Ash.read!()

Helpdesk.Support.Ticket
|> Ash.Query.filter(status == :closed and not(contains(subject, "4")))
|> Ash.DataLayer.Simple.set_data(tickets)
|> Ash.read!()
```

## Relationship

```
ticket = (
  Helpdesk.Support.Ticket
  |> Ash.Changeset.for_create(:open, %{subject: "I can't find my hand!"})
  |> Ash.create!()
)

representative = (
  Helpdesk.Support.Representative
  |> Ash.Changeset.for_create(:create, %{name: "Joe Armstrong"})
  |> Ash.create!()
)

ticket
|> Ash.Changeset.for_update(:assign, %{representative_id: representative.id})
|> Ash.update!()
```