defmodule Auth0Ex do
  alias Auth0Ex.Consumer

  def token_for(audience) do
    Consumer.token_for(Consumer, audience)
  end
end
