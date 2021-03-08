defmodule Auth0Ex.Token do
  use Joken.Config

  add_hook(JokenJwks, strategy: Auth0Ex.JwksStrategy)
end
