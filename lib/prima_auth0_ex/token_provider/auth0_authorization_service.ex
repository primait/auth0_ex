defmodule PrimaAuth0Ex.TokenProvider.Auth0AuthorizationService do
  @moduledoc """
  Implementation of `PrimaAuth0Ex.TokenProvider.AuthorizationService` for Auth0.
  """

  @behaviour PrimaAuth0Ex.TokenProvider.AuthorizationService

  require Logger
  alias PrimaAuth0Ex.Auth0Credentials
  alias PrimaAuth0Ex.OpenIDConfiguration
  alias PrimaAuth0Ex.TokenProvider.Auth0ClientAssertion
  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  @impl PrimaAuth0Ex.TokenProvider.AuthorizationService
  def retrieve_token(credentials, audience) do
    openid_configuration = OpenIDConfiguration.fetch!(credentials.base_url)
    url = openid_configuration.token_endpoint

    Logger.info("Requesting token to Auth0",
      client: credentials.client,
      audience: audience,
      url: url
    )

    result =
      case body(credentials, audience, openid_configuration.issuer) do
        {:ok, request_body} ->
          url
          |> Telepoison.post(request_body, "content-type": "application/json")
          |> parse_response()

        {:error, _reason} = error ->
          error
      end

    emit_event(result, audience)
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    case Jason.decode(body) do
      {:ok, %{"token_type" => "Bearer", "access_token" => access_token}} ->
        {:ok, TokenInfo.from_jwt(access_token)}

      response ->
        Logger.warning("Invalid response from Auth0", response: inspect(response))
        {:error, :invalid_auth0_response}
    end
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: status_code}}) do
    Logger.warning("Request to Auth0 failed", status_code: status_code)
    {:error, :request_error}
  end

  defp parse_response({:error, message}) do
    Logger.warning("Error sending request to Auth0", error: inspect(message))
    {:error, message}
  end

  defp body(%Auth0Credentials{authentication_method: :client_secret} = credentials, audience, _issuer) do
    {:ok,
     Jason.encode!(%{
       grant_type: "client_credentials",
       client_id: credentials.client_id,
       client_secret: credentials.client_secret,
       audience: audience
     })}
  end

  defp body(%Auth0Credentials{authentication_method: :private_key_jwt} = credentials, audience, issuer) do
    with {:ok, assertion} <- Auth0ClientAssertion.generate(credentials, issuer) do
      # Auth0 identifies the client from the assertion's `iss` claim.
      {:ok,
       Jason.encode!(%{
         grant_type: "client_credentials",
         client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
         client_assertion: assertion,
         audience: audience
       })}
    end
  end

  defp body(%Auth0Credentials{authentication_method: method}, _audience, _issuer) do
    {:error, {:unsupported_authentication_method, method}}
  end

  defp emit_event({:error, _} = result, audience) do
    :telemetry.execute([:prima_auth0_ex, :retrieve_token, :failure], %{count: 1}, %{
      audience: audience
    })

    result
  end

  defp emit_event({:ok, _} = result, audience) do
    :telemetry.execute([:prima_auth0_ex, :retrieve_token, :success], %{count: 1}, %{
      audience: audience
    })

    result
  end
end
