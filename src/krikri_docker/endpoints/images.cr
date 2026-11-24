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
      @client.call("GET", "/images/#{URL.path_segment(name)}/json") do |response|
        return Types::Image.from_json(response.body)
      end
    end

    # The daemon's own inspect payload, verbatim - what Ansible reports in a
    # module result, where the typed model would drop fields the daemon sent.
    def inspect_json(name : String) : JSON::Any
      @client.call("GET", "/images/#{URL.path_segment(name)}/json") do |response|
        return JSON.parse(response.body)
      end
    end

    # Pulls an image from a registry.
    #
    # The query is built in the Docker Python SDK's own order and encoding
    # ("tag" then "fromImage" then "platform"), because Ansible quotes that
    # URL in a failed pull's message.
    #
    # - registry_auth: base64url-encoded credentials for the target
    #   registry, sent as `X-Registry-Auth` (the SDK's
    #   auth.get_config_header). nil sends no header.
    # - platform: the `platform` query parameter ("linux/amd64", ...).
    #
    # Docker Engine reports a pull failure it discovers after it started
    # streaming progress as HTTP 200 with an `{"error": ...}` line in the
    # body, so the stream is scanned and a failed line raises
    # Errors::ImagePullError - a status check alone would report success.
    def pull(
      repository : String,
      tag : String,
      registry_auth : String? = nil,
      platform : String? = nil,
    ) : Nil
      query = "tag=#{URL.form_encode(tag)}&fromImage=#{URL.form_encode(repository)}"
      query += "&platform=#{URL.form_encode(platform)}" if platform
      headers = registry_auth ? HTTP::Headers{"X-Registry-Auth" => registry_auth} : nil

      @client.call("POST", "/images/create?#{query}", headers) do |response|
        raise_on_stream_error(response.body)
      end
    end

    # Deletes a specific image by its reference.
    #
    # `force` is always sent, with Python's True/False spelling, and
    # `noprune` only when the caller asked for it - the same query the
    # community.docker module sends.
    def delete(name : String, force : Bool = false, no_prune : Bool? = nil) : Nil
      params = "force=#{URL.python_bool(force)}"
      params += "&noprune=#{URL.python_bool(no_prune)}" if no_prune

      @client.call("DELETE", "/images/#{URL.path_segment(name)}?#{params}") { }
    end

    private def raise_on_stream_error(body : String) : Nil
      return unless body.includes?("\"error")

      body.each_line do |line|
        line = line.strip
        next if line.empty?

        parsed = begin
          JSON.parse(line)
        rescue JSON::ParseException
          next
        end

        error = parsed["error"]?.try(&.as_s?)
        next if error.nil? || error.empty?

        raise Errors::ImagePullError.new(error, parsed["errorDetail"]?)
      end
    end
  end
end
