defmodule UrlShortener.Schema.Urls do
  use Ecto.Schema
  import Ecto.Changeset


  schema "urls" do
    field :full_url, :string
    field :short_url, :string
    field :valid_until, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(url, attrs) do
    url
    |> cast(attrs, [:short_url, :full_url, :valid_until])
    |> validate_required([:short_url, :full_url, :valid_until])
    |> unique_constraint(:short_url)
    |> unique_constraint(:full_url)
  end
end
