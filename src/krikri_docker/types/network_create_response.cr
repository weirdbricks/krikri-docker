require "json"

module KrikriDocker::Types
  class NetworkCreateResponse
    include JSON::Serializable

    # The ID of the created network.
    @[JSON::Field(key: "Id")]
    property id : String
  end
end
