require "json"

module KrikriDocker::Types
  # One entry of `GET /containers/json`.
  class ContainerSummary
    include JSON::Serializable

    @[JSON::Field(key: "Id")]
    property id : String

    @[JSON::Field(key: "Names")]
    property names : Array(String)

    @[JSON::Field(key: "Image")]
    property image : String

    @[JSON::Field(key: "State")]
    property state : String
  end
end
