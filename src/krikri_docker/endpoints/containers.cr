require "../client"
require "../types/*"
require "../url"

module KrikriDocker::Endpoints
  # Container endpoints of the Docker Engine API.
  class Containers
    getter client : Client

    def initialize(@client)
    end

    # Fetches a list of containers.
    #
    # The query is built the way the SDK's container lookup builds it
    # (`limit=-1&all=1&size=0&trunc_cmd=0`, filters only when given), since a
    # failed request's message quotes this URL.
    #
    # - all: If true, list all containers. Default is false.
    # - limit: The maximum number of containers to list (-1 means no limit).
    # - size: If true, fetch container sizes. Default is false.
    # - filters: Container filter criteria. Default is an empty hash.
    def list(all : Bool = false, limit : Int32 = -1, size : Bool = false, filters = Hash(String, Array(String)).new) : Array(Types::ContainerSummary)
      query = "limit=#{limit}&all=#{all ? 1 : 0}&size=#{size ? 1 : 0}&trunc_cmd=0"
      query += "&filters=#{URL.form_encode(filters.to_json)}" unless filters.empty?

      @client.call("GET", "/containers/json?#{query}") do |response|
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
      @client.call("GET", "/containers/#{URL.path_segment(id)}/json") do |response|
        return Types::ContainerInspectResponse.from_json(response.body)
      end
    end

    # The daemon's own inspect payload, verbatim - what Ansible reports in a
    # module result, where the typed model would drop fields the daemon sent.
    def inspect_json(id : String) : JSON::Any
      @client.call("GET", "/containers/#{URL.path_segment(id)}/json", HTTP::Headers{"Accept" => "application/json"}) do |response|
        return JSON.parse(response.body)
      end
    end

    # Starts a specific container.
    #
    # - id: ID of the container to start.
    def start(id : String) : Nil
      @client.call("POST", "/containers/#{URL.path_segment(id)}/start") { }
    end

    # Stops a specific container.
    #
    # - id: ID of the container to stop.
    def stop(id : String) : Nil
      @client.call("POST", "/containers/#{URL.path_segment(id)}/stop") { }
    end

    # Deletes a specific container.
    #
    # The parameters and their order are the SDK's own
    # (`v`, `link`, `force`, with Python's True/False spelling).
    #
    # - id: ID of the container to delete.
    # - volumes: If true, remove associated volumes. Default is false.
    # - link: If true, remove the link. Default is false.
    # - force: If true, force deletion. Default is false.
    def delete(id : String, volumes : Bool = false, link : Bool = false, force : Bool = false) : Nil
      params = "v=#{URL.python_bool(volumes)}&link=#{URL.python_bool(link)}&force=#{URL.python_bool(force)}"

      @client.call("DELETE", "/containers/#{URL.path_segment(id)}?#{params}") { }
    end
  end
end
