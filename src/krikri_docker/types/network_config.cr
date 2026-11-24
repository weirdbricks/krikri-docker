require "json"

module KrikriDocker::Types
  # The fields of a `POST /networks/create` body this client builds.
  class NetworkConfig
    include JSON::Serializable

    @[JSON::Field(key: "Name")]
    property name : String

    @[JSON::Field(key: "Driver")]
    property driver : String

    # Restrict external access to the network.
    @[JSON::Field(key: "Internal")]
    property internal : Bool?

    # Globally scoped network is manually attachable by regular containers
    # from workers in swarm mode.
    @[JSON::Field(key: "Attachable")]
    property attachable : Bool?

    # User-defined key/value metadata.
    @[JSON::Field(key: "Labels")]
    property labels : Hash(String, String)?

    def initialize(
      @name,
      @driver = "bridge",
      @internal = nil,
      @attachable = nil,
      @labels = nil,
    )
    end
  end
end
