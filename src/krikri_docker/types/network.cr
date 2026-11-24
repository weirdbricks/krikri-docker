require "json"

module KrikriDocker::Types
  class Network
    include JSON::Serializable

    @[JSON::Field(key: "Name")]
    property name : String

    @[JSON::Field(key: "Id")]
    property id : String

    @[JSON::Field(key: "Driver")]
    property driver : String

    @[JSON::Field(key: "IPAM")]
    property ipam : KrikriDocker::Types::IPAM?

    @[JSON::Field(key: "Containers")]
    property containers : Hash(String, KrikriDocker::Types::NetworkContainer)?
  end
end
