require "json"

module KrikriDocker::Types
  class NetworkContainer
    include JSON::Serializable

    @[JSON::Field(key: "Name")]
    property name : String
  end
end
