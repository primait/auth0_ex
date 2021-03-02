defmodule Auth0Ex.Consumer.CachedTokenServiceTest do
  use ExUnit.Case, async: true

  import Hammox
  alias Auth0Ex.Auth0Credentials
  alias Auth0Ex.Consumer.CachedTokenService

  @credentials %Auth0Credentials{base_url: "base_url", client_id: "client_id", client_secret: "client_secret"}

  setup :verify_on_exit!

  describe "retrieve_token/2" do
    test "returns a token from cache, when available" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:ok, "CACHED-TOKEN"} end)

      assert {:ok, "CACHED-TOKEN"} = CachedTokenService.retrieve_token(@credentials, "target-audience")
    end

    test "returns a fresh token and updates cache if a cached token is not available" do
      expect(TokenCacheMock, :get_token_for, fn "target-audience" -> {:error, :not_found} end)
      expect(AuthorizationServiceMock, :retrieve_token, fn @credentials, "target-audience" -> {:ok, "FRESH-TOKEN"} end)
      expect(TokenCacheMock, :set_token_for, fn "target-audience", "FRESH-TOKEN" -> :ok end)

      assert {:ok, "FRESH-TOKEN"} = CachedTokenService.retrieve_token(@credentials, "target-audience")
    end
  end
end
