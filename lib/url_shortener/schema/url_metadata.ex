defmodule UrlShortener.Schema.UrlMetadata do
  use Ecto.Schema
  import Ecto.Changeset


  schema "url_metadata" do
    belongs_to(:urls, UrlShortener.Schema.Urls)
    field(:metadata, :map)
    timestamps()
  end

  @doc false
  def changeset(url_metadata = %__MODULE__{}, attrs) do
    url_metadata
    |> cast(attrs, [:urls_id, :metadata])
    |> validate_required([:urls_id, :metadata])
    |> foreign_key_constraint(:urls)
  end
end
