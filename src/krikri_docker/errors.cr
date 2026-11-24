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
    # with an empty or non-JSON body). nil when the body carries none, which
    # is also when the SDK omits the quoted explanation entirely.
    getter daemon_message : String?

    def initialize(@status_code : Int32, @reason : String, @body : String, @url : String)
      @daemon_message = self.class.daemon_message(@body)
      super "Code: #{@status_code} Message: #{@daemon_message}"
    end

    def initialize(response : KrikriDocker::Response)
      initialize(response.status_code, response.reason, response.body, response.url)
    end

    def self.daemon_message(body : String) : String?
      return if body.strip.empty?

      if fields = JSON.parse(body).as_h?
        if value = fields["message"]?
          case raw = value.raw
          when String               then return raw
          when Int64, Float64, Bool then return raw.to_s
          end
        end
      end
      body.strip
    rescue JSON::ParseException
      body.strip
    end
  end

  # Raised by Images#pull when the daemon answers with a progress stream
  # that contains an error line. Docker Engine reports pull failures that
  # way (HTTP 200 with `{"error": ...}` in the stream) once it has started
  # writing progress, so a status-code check alone reports success.
  class ImagePullError < Exception
    # The stream line's `error` text.
    getter error : String

    # The stream line's `errorDetail` object, when the daemon sent one.
    getter error_detail : JSON::Any?

    def initialize(@error : String, @error_detail : JSON::Any? = nil)
      super @error
    end

    def code : String?
      error_detail.try(&.["code"]?).try(&.raw.to_s)
    end

    def message : String?
      error_detail.try(&.["message"]?).try(&.raw.to_s)
    end
  end

  # Raised by Client#api_version when /version answered without the API
  # version key - the SDK's own text for the same condition.
  class InvalidVersionError < Exception
    def initialize
      super %(Invalid response from docker daemon: key "ApiVersion" is missing.)
    end
  end
end
