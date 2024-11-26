defmodule Integration.TokenCache.DynamoDBTest do
  alias PrimaAuth0Ex.TokenCache.DynamoDB

  use PrimaAuth0Ex.TestSupport.TokenCacheBehaviorCaseTemplate,
    async: true,
    cache_module: DynamoDB,
    # Token expiration is managed by aws, and could take days for old tokens to be deleted,
    # so we don't cover that in the tests here
    test_token_expiration: false

  setup do
    cache_env = Application.get_env(:prima_auth0_ex, :dynamodb_cache)

    on_exit(fn ->
      if cache_env == nil do
        Application.delete_env(:prima_auth0_ex, :dynamodb_cache)
      else
        Application.put_env(:prima_auth0_ex, :dynamodb_cache, cache_env)
      end
    end)

    DynamoDB.delete_table()
    DynamoDB.init()
  end
end
