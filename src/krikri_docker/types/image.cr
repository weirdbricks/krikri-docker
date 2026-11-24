require "json"

module KrikriDocker::Types
  # The fields of `GET /images/<ref>/json` this client reads. The raw payload
  # a module result reports comes from Images#inspect_json.
  class Image
    include JSON::Serializable

    @[JSON::Field(key: "Id")]
    property id : String

    # nil for an image the daemon has no config for (an imported or
    # scratch-built artifact) - the Docker Engine API returns `Config: null`
    # there, and a non-nilable field would crash parsing.
    @[JSON::Field(key: "Config")]
    property config : KrikriDocker::Types::ContainerConfig?
  end
end
