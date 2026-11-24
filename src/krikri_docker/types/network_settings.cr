require "json"

module KrikriDocker::Types
  # The one field of an inspect response's NetworkSettings this client reads:
  # which networks the container is attached to.
  class NetworkSettings
    include JSON::Serializable

    @[JSON::Field(key: "Networks")]
    property networks : Hash(String, KrikriDocker::Types::EndpointSettings)
  end
end
