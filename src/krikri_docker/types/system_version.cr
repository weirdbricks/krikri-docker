require "json"

module KrikriDocker::Types
  class SystemVersion
    include JSON::Serializable

    # The version of the daemon
    @[JSON::Field(key: "Version")]
    property version : String

    # The default (and highest) API version that is supported by the daemon
    @[JSON::Field(key: "ApiVersion")]
    property api_version : String

    # The minimum API version that is supported by the daemon
    @[JSON::Field(key: "MinAPIVersion")]
    property min_api_version : String?
  end
end
