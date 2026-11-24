require "../client"
require "../types/*"

module KrikriDocker::Endpoints
  # Daemon-wide endpoints of the Docker Engine API.
  class System
    getter client : Client

    def initialize(@client)
    end

    # Authenticates against a registry.
    #
    # The payload is the same one the Docker Python SDK's login() puts on the
    # wire: its `_post_json` drops None values, so the email key the SDK
    # would carry is absent here too.
    def auth(username : String, password : String, server_address : String) : Nil
      headers = HTTP::Headers{"Content-Type" => "application/json"}
      body = {"username" => username, "password" => password, "serveraddress" => server_address}.to_json

      @client.call("POST", "/auth", headers, body) { }
    end

    # Retrieves the daemon version and the API versions it supports.
    def version : Types::SystemVersion
      @client.call("GET", "/version") do |response|
        return Types::SystemVersion.from_json(response.body)
      end
    end
  end
end
