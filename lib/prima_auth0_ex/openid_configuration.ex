defmodule PrimaAuth0Ex.OpenIDConfiguration do
  @moduledoc "Credentials to access Auth0"

  @type t :: %__MODULE__{issuer: String.t(), token_endpoint: String.t(), jwks_uri: String.t()}

  @struct_keys [:issuer, :token_endpoint, :jwks_uri]
  defstruct @struct_keys

  @spec fetch(String.t()) :: __MODULE__.t()
  def fetch(base_url) do
    %HTTPoison.Response{status_code: status_code, body: meta_body} = base_url |> oidc_metadata_url |> Telepoison.get!()
    true = status_code in 200..299

    metadata = Jason.decode!(meta_body)

    metadata = Map.new(@struct_keys, fn key -> {key, metadata[Atom.to_string(key)]} end)

    struct!(__MODULE__, metadata)
  end

  defp oidc_metadata_url(base_url), do: base_url <> "/.well-known/openid-configuration"
end
