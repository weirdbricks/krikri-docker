require "../client"
require "../types/*"

module KrikriDocker::Endpoints
  # Volume endpoints of the Docker Engine API.
  #
  # Every method returns the daemon's own JSON: Ansible reports a volume's
  # raw payload in a module result, so a typed model would drop fields the
  # daemon sent.
  class Volumes
    getter client : Client

    def initialize(@client)
    end

    # Retrieves the daemon's volume listing.
    def list_json : JSON::Any
      @client.call("GET", "/volumes") do |response|
        return JSON.parse(response.body)
      end
    end

    # Creates a volume and returns the daemon's own response.
    #
    # Labels are only sent when the caller gave them at all (Ansible
    # distinguishes an explicit null from an empty set).
    def create(
      name : String,
      driver : String = "local",
      driver_opts : Hash(String, JSON::Any)? = nil,
      labels : Hash(String, JSON::Any)? = nil,
    ) : JSON::Any
      payload = {
        "Name"       => JSON::Any.new(name),
        "Driver"     => JSON::Any.new(driver),
        "DriverOpts" => JSON::Any.new(driver_opts || ({} of String => JSON::Any)),
      } of String => JSON::Any
      payload["Labels"] = JSON::Any.new(labels) if labels
      headers = HTTP::Headers{"Content-Type" => "application/json", "Accept" => "application/json"}

      @client.call("POST", "/volumes/create", headers, JSON::Any.new(payload).to_json) do |response|
        return parse_body(response.body) || JSON::Any.new(nil)
      end
    end

    # Inspects a specific volume by its name; nil when it does not exist.
    def get_json(name : String) : JSON::Any?
      @client.call("GET", "/volumes/#{name}", HTTP::Headers{"Accept" => "application/json"}) do |response|
        return parse_body(response.body)
      end
    rescue ex : Errors::DockerAPIError
      return nil if ex.status_code == 404
      raise ex
    end

    # Deletes a specific volume by its name.
    def remove(name : String, force : Bool = false) : Nil
      path = force ? "/volumes/#{name}?force=true" : "/volumes/#{name}"
      @client.call("DELETE", path) { }
    end

    private def parse_body(body : String) : JSON::Any?
      body.empty? ? nil : JSON.parse(body)
    end
  end
end
