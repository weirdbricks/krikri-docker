require "../client"
require "../types/*"
require "../url"

module KrikriDocker::Endpoints
  # Image endpoints of the Docker Engine API.
  class Images
    getter client : Client

    def initialize(@client)
    end

    # Inspects a specific image by its reference.
    def inspect(name : String) : Types::Image
      @client.call("GET", "/images/#{name}/json") do |response|
        return Types::Image.from_json(response.body)
      end
    end

    # The daemon's own inspect payload, verbatim - what Ansible reports in a
    # module result, where the typed model would drop fields the daemon sent.
    def inspect_json(name : String) : JSON::Any
      @client.call("GET", "/images/#{name}/json") do |response|
        return JSON.parse(response.body)
      end
    end

    # Pulls an image from a registry.
    #
    # The query is built in the Docker Python SDK's own order and encoding
    # ("tag" then "fromImage"), because Ansible quotes that URL in a failed
    # pull's message.
    def pull(repository : String, tag : String) : Nil
      query = "tag=#{URL.form_encode(tag)}&fromImage=#{URL.form_encode(repository)}"
      @client.call("POST", "/images/create?#{query}") { }
    end

    # Deletes a specific image by its reference.
    #
    # - force: Force removal of the image. Default is false.
    # - no_prune: Do not delete untagged parents. Default is false.
    def delete(name : String, force : Bool = false, no_prune : Bool = false) : Nil
      params = URI::Params{
        "force"   => [force.to_s],
        "noprune" => [no_prune.to_s],
      }

      @client.call("DELETE", "/images/#{name}?#{params}") { }
    end
  end
end
