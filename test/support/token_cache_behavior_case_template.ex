defmodule PrimaAuth0Ex.TestSupport.TokenCacheBehaviorCaseTemplate do
  @moduledoc false

  use ExUnit.CaseTemplate
  import PrimaAuth0Ex.TestSupport.TimeUtils

  alias PrimaAuth0Ex.TokenProvider.TokenInfo

  using options do
    cache_module = Keyword.fetch!(options, :cache_module)
    # Whether this behavior actually persists tokens.
    # Probably only useful for the noop token cache
    persists_tokens = Keyword.get(options, :test_persists_tokens, true)
    # Whether this behavior expires tokens automatically
    expires_tokens = Keyword.get(options, :test_token_expiration, persists_tokens)

    quote do
      defp sample_token do
        %TokenInfo{
          jwt: "my-token",
          issued_at: one_hour_ago(),
          expires_at: in_one_hour(),
          kid: "my-kid"
        }
      end

      def cache_module do
        unquote(cache_module)
      end

      def client_name do
        :default_client
      end

      def test_audience do
        mod = "ASDF"
        test_name = "BSDF"
        "#{Macro.underscore(mod)}:#{test_name}"
      end

      describe "token cache" do
        @tag :asdf
        test "returns {:ok, nil} when token is not cached" do
          assert {:ok, nil} == cache_module().get_token_for(client_name(), test_audience())
        end

        if unquote(persists_tokens) do
          test "persists and retrieves tokens" do
            token = sample_token()
            :ok = cache_module().set_token_for(client_name(), test_audience(), token)

            assert {:ok, token} == cache_module().get_token_for(client_name(), test_audience())
          end
        end

        if unquote(expires_tokens) do
          test "tokens are purged from cache when they expire" do
            token = %TokenInfo{sample_token() | expires_at: shifted_by_seconds(2)}
            :ok = cache_module().set_token_for(client_name(), test_audience(), token)
            :timer.sleep(1000)
            # Token shouldn't have expired yet
            assert {:ok, ^token} = cache_module().get_token_for(client_name(), test_audience())

            :timer.sleep(2100)
            # Token expired
            assert {:ok, nil} = cache_module().get_token_for(client_name(), test_audience())
          end
        end
      end
    end
  end
end
