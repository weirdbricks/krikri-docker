require "json"

module KrikriDocker::Types
  # The fields of `GET /containers/<id>/json` this client reads. The raw
  # payload a module result reports comes from Containers#inspect_json, not
  # from this model (which would drop fields the daemon sent).
  class ContainerInspectResponse
    include JSON::Serializable

    @[JSON::Field(key: "HostConfig")]
    property host_config : KrikriDocker::Types::HostConfig

    @[JSON::Field(key: "Config")]
    property config : KrikriDocker::Types::ContainerConfig

    @[JSON::Field(key: "NetworkSettings")]
    property network_settings : KrikriDocker::Types::NetworkSettings
  end
end
