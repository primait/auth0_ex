defmodule PrimaAuth0Ex.OpenIDConfiguration do
  @moduledoc false
  @doc """
    Module for fetching and parsing the [rfc8414](https://www.rfc-editor.org/rfc/rfc8414) openid metadata endpoint

    This allows auth0_ex to be agnostic of the actual openid server
  """

  @type t :: %__MODULE__{issuer: String.t(), token_endpoint: String.t(), jwks_uri: String.t()}

  @struct_keys [:issuer, :token_endpoint, :jwks_uri]
  defstruct @struct_keys

  @doc """
    Fetches the openid metadata.

    Doesn't implement caching and always makes a http request, avoid calling this in hot code paths
  """
  @spec fetch!(String.t()) :: __MODULE__.t()
  def fetch!(base_url) do
    url = metadata_url(base_url)
    %HTTPoison.Response{status_code: status_code, body: meta_body} = Telepoison.get!(url, accept: "application/json")

    unless status_code in 200..299 do
      raise """
      Failed to retrieve the openid-configuration from #{url}, server sent ${status_code}:
      #{meta_body}

      This is most likely caused by an incorrect base_url.
      """
    end

    metadata = Jason.decode!(meta_body)
    metadata = Map.new(@struct_keys, fn key -> {key, metadata[Atom.to_string(key)]} end)

    struct!(__MODULE__, metadata)
  end

  @spec metadata_url(String.t()) :: String.t() | no_return
  defp metadata_url(base_url),
    do:
      base_url
      |> URI.new!()
      |> URI.append_path("/.well-known/openid-configuration")
      |> URI.to_string()
end
