defmodule UrlShortener.Schema.UrlMetadata do
  use Ecto.Schema
  import Ecto.Changeset


  schema "url_metadata" do
    field(:short_url, :string)
    field(:full_url, :string)
    field(:metadata, :map)
    timestamps()
  end

  @doc false
  def changeset(url_metadata = %__MODULE__{}, attrs) do
    url_metadata
    |> cast(attrs, [:short_url, :full_url, :metadata])
    |> validate_required([:short_url, :full_url, :metadata])
  end
end
