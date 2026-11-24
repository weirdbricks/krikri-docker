require "json"

module KrikriDocker::Types
  class ContainerCreateResponse
    include JSON::Serializable

    # The ID of the created container
    @[JSON::Field(key: "Id")]
    property id : String
  end
end
