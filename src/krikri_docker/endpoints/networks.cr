require "../client"
require "../types/*"

module KrikriDocker::Endpoints
  # Network endpoints of the Docker Engine API.
  class Networks
    getter client : Client

    def initialize(@client)
    end

    # Retrieves a list of all networks.
    def list : Array(Types::Network)
      @client.call("GET", "/networks") do |response|
        return Array(Types::Network).from_json(response.body)
      end
    end

    # Creates a new network using the given configuration.
    def create(config : Types::NetworkConfig)
      headers = HTTP::Headers{"Content-Type" => "application/json"}

      @client.call("POST", "/networks/create", headers, config.to_json) do |response|
        return Types::NetworkCreateResponse.from_json(response.body)
      end
    end

    # Creates a new network from a fully-built JSON body, for callers whose
    # payload is assembled key by key (the Docker API's own optional keys
    # sent as explicit nulls) rather than from NetworkConfig.
    def create(payload : JSON::Any) : Types::NetworkCreateResponse
      headers = HTTP::Headers{"Content-Type" => "application/json"}

      @client.call("POST", "/networks/create", headers, payload.to_json) do |response|
        return Types::NetworkCreateResponse.from_json(response.body)
      end
    end

    # Inspects a specific network by its ID or name.
    def inspect(id : String) : Types::Network
      @client.call("GET", "/networks/#{id}") do |response|
        return Types::Network.from_json(response.body)
      end
    end

    # The daemon's own inspect payload, verbatim - what Ansible reports in a
    # module result, where the typed model would drop fields the daemon sent.
    def get_json(id : String) : JSON::Any
      @client.call("GET", "/networks/#{id}", HTTP::Headers{"Accept" => "application/json"}) do |response|
        return JSON.parse(response.body)
      end
    end

    # Connects a container to a network.
    #
    # endpoint_config carries the per-attachment settings the daemon accepts
    # (aliases, links, a static IPAM address) - nil sends just the container.
    def connect(network : String, container : String, endpoint_config : Hash(String, JSON::Any)? = nil) : Nil
      payload = {"Container" => JSON::Any.new(container)} of String => JSON::Any
      payload["EndpointConfig"] = JSON::Any.new(endpoint_config) if endpoint_config
      headers = HTTP::Headers{"Content-Type" => "application/json"}

      @client.call("POST", "/networks/#{network}/connect", headers, payload.to_json) { }
    end

    # Disconnects a container from a network.
    def disconnect(network : String, container : String) : Nil
      headers = HTTP::Headers{"Content-Type" => "application/json"}
      body = {"Container" => container}.to_json

      @client.call("POST", "/networks/#{network}/disconnect", headers, body) { }
    end

    # Deletes a specific network by its ID or name.
    def delete(id : String) : Nil
      @client.call("DELETE", "/networks/#{id}") { }
    end
  end
end
