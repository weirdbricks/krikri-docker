require "json"

require "./response"

module KrikriDocker::Errors
  # Raised by Client#call for a non-2xx daemon response.
  #
  # Carries everything the Docker Python SDK's APIError wording needs - the
  # request URL, status code, reason phrase and raw body - plus the daemon's
  # own message extracted from the body, so callers can render their own
  # error text without re-reading anything or asking the daemon again.
  class DockerAPIError < Exception
    # The HTTP status code associated with the error.
    getter status_code : Int32

    # The status line's reason phrase ("Internal Server Error", ...).
    getter reason : String

    # The response body, verbatim.
    getter body : String

    # The request path the failed call used.
    getter url : String

    # The daemon's own message - the `message` field of a JSON error body,
    # or the raw body when it isn't JSON (some daemons answer an API error
    # with an empty or non-JSON body; Podman's compat API 500s an
    # unparseable image reference with no JSON at all).
    getter daemon_message : String

    def initialize(@status_code : Int32, @reason : String, @body : String, @url : String)
      @daemon_message = self.class.daemon_message(@body)
      super "Code: #{@status_code} Message: #{@daemon_message}"
    end

    def initialize(response : KrikriDocker::Response)
      initialize(response.status_code, response.reason, response.body, response.url)
    end

    def self.daemon_message(body : String) : String
      return "" if body.strip.empty?

      parsed = JSON.parse(body).as_h?
      message = parsed.try { |fields| fields["message"]?.try { |value| value.as_s? } }
      message || body.strip
    rescue JSON::ParseException
      body.strip
    end
  end

  # Custom exception class for Docker build errors.
  class DockerBuildError < Exception
    # Initializes a new instance of the Docker build error.
    #
    # - message: A message describing the build error.
    def initialize(message : String?)
      super "Docker Build Error: #{message}"
    end
  end
end
