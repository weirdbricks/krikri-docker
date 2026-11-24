require "http/status"

module KrikriDocker
  # One completed request/response exchange, body read in full.
  #
  # #request never raises for a non-2xx status - the response (including the
  # raw error body) is handed back so callers can render their own wording.
  # #call is the raising convenience layer used by the endpoint wrappers.
  struct Response
    getter status_code : Int32
    getter reason : String
    getter body : String
    getter url : String

    def initialize(@status_code, @reason, @body, @url)
    end

    def success? : Bool
      200 <= @status_code < 300
    end

    # The response's canonical reason phrase when the daemon sent none -
    # the same text the Ruby/Python SDKs quote for the codes a Docker
    # daemon answers with.
    def self.reason_phrase(status : Int32) : String
      text = HTTP::Status.new(status).to_s
      # An unknown code renders as its bare number - no reason phrase to
      # quote, same as the SDK seeing an unrecognized status line.
      return "" if text.matches?(/\A\d+\z/)

      text.split('_').map(&.capitalize).join(' ')
    rescue ArgumentError
      ""
    end
  end
end
