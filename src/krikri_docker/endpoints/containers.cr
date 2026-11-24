require "../client"
require "../types/*"

module KrikriDocker::Endpoints
  # Container endpoints of the Docker Engine API.
  class Containers
    getter client : Client

    def initialize(@client)
    end

    # Fetches a list of containers.
    #
    # - all: If true, list all containers. Default is false.
    # - limit: The maximum number of containers to list.
    # - size: If true, fetch container sizes. Default is false.
    # - filters: Container filter criteria. Default is an empty hash.
    def list(all : Bool = false, limit : Int32? = nil, size : Bool = false, filters = Hash(String, Array(String)).new) : Array(Types::ContainerSummary)
      params = URI::Params{
        "all"     => [all.to_s],
        "limit"   => [limit.to_s],
        "size"    => [size.to_s],
        "filters" => [filters.to_json],
      }

      @client.call("GET", "/containers/json?#{params}") do |response|
        return Array(Types::ContainerSummary).from_json(response.body)
      end
    end

    # Creates a new container.
    #
    # - name: Name of the container.
    # - config: Configuration for creating the container.
    def create(name : String, config : Types::CreateContainerConfig) : Types::ContainerCreateResponse
      params = URI::Params{
        "name" => [name],
      }

      headers = HTTP::Headers{
        "Content-Type" => "application/json",
      }

      @client.call("POST", "/containers/create?#{params}", headers, config.to_json) do |response|
        return Types::ContainerCreateResponse.from_json(response.body)
      end
    end

    # Inspects a specific container.
    #
    # - id: ID or name of the container to inspect.
    def inspect(id : String) : Types::ContainerInspectResponse
      @client.call("GET", "/containers/#{id}/json") do |response|
        return Types::ContainerInspectResponse.from_json(response.body)
      end
    end

    # The daemon's own inspect payload, verbatim - what Ansible reports in a
    # module result, where the typed model would drop fields the daemon sent.
    def inspect_json(id : String) : JSON::Any
      @client.call("GET", "/containers/#{id}/json", HTTP::Headers{"Accept" => "application/json"}) do |response|
        return JSON.parse(response.body)
      end
    end

    # Starts a specific container.
    #
    # - id: ID of the container to start.
    def start(id : String) : Nil
      @client.call("POST", "/containers/#{id}/start") { }
    end

    # Stops a specific container.
    #
    # - id: ID of the container to stop.
    def stop(id : String) : Nil
      @client.call("POST", "/containers/#{id}/stop") { }
    end

    # Deletes a specific container.
    #
    # - id: ID of the container to delete.
    # - volumes: If true, remove associated volumes. Default is false.
    # - force: If true, force deletion. Default is false.
    # - link: If true, remove the link. Default is false.
    def delete(id : String, volumes : Bool = false, force : Bool = false, link : Bool = false) : Nil
      params = URI::Params{
        "v"     => [volumes.to_s],
        "force" => [force.to_s],
        "link"  => [link.to_s],
      }

      @client.call("DELETE", "/containers/#{id}?#{params}") { }
    end
  end
end
