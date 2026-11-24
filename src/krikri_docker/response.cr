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

    # The canonical reason phrase for a status code, used only when the
    # daemon sent no phrase on its status line. HTTP::Status#description is
    # exactly the text requests would have quoted ("Internal Server Error",
    # "I'm a teapot"); an unknown code has none and renders empty, like the
    # SDK seeing an unrecognized status line.
    def self.reason_phrase(status : Int32) : String
      HTTP::Status.new(status).description || ""
    rescue ArgumentError
      ""
    end
  end
end
