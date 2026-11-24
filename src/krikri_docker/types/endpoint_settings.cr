require "json"

module KrikriDocker::Types
  # A container's attachment to one network. Only the network NAME (the hash
  # key in NetworkSettings#networks) is read, so no field is declared here;
  # the daemon's per-attachment details are ignored when parsing.
  class EndpointSettings
    include JSON::Serializable
  end
end
