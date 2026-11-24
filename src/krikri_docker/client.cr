require "http/client"
require "json"
require "socket"

require "./errors"
require "./response"

module KrikriDocker
  # API client for the Docker Engine API.
  #
  # Subclasses HTTP::Client (rather than wrapping a single UNIXSocket handed
  # to HTTP::Client.new(io)) so it can actually reconnect: HTTP::Client's own
  # raw-IO constructor sets @reconnect = false, so once the daemon closes a
  # connection (or a response body isn't fully drained, desyncing the
  # HTTP/1.1 framing on a shared keep-alive connection - both are common
  # with the Docker API), every subsequent call on that client raises
  # "This HTTP::Client cannot be reconnected". Overriding the private #io
  # method instead - the same pattern HTTP::Client itself uses to lazily
  # (re)connect over TCP/TLS - lets a fresh UNIXSocket be opened on demand.
  class Client < HTTP::Client
    # Default Docker daemon socket path, matching the Docker CLI/SDKs' own
    # default.
    DEFAULT_SOCKET_PATH = "/var/run/docker.sock"

    @socket_path : String?
    @tls_hostname : String?
    @api_version : String?

    # Initializes a new instance talking to a local UNIX socket (the common
    # case - a local or rootless Docker/Podman daemon).
    #
    # - socket_path: path to the Docker daemon's UNIX socket. Defaults to
    #   the DOCKER_HOST environment variable (a unix:// URL, the same
    #   convention the Docker CLI and every other Docker SDK honor - useful
    #   for rootless Docker/Podman, where the daemon socket usually isn't
    #   at DEFAULT_SOCKET_PATH and isn't reachable by an unprivileged user
    #   even when it is), falling back to DEFAULT_SOCKET_PATH if unset.
    def initialize(socket_path : String? = nil)
      super(host: "localhost")
      @socket_path = socket_path || docker_host_socket_path || DEFAULT_SOCKET_PATH
    end

    # Initializes a new instance talking to a *remote* Docker daemon over
    # TCP, optionally TLS-secured - the `tls` param is `HTTP::Client`'s own
    # `TLSContext` (`nil` for plain TCP, `true` for TLS with default
    # verification, or an `OpenSSL::SSL::Context::Client` for full control
    # over certs/verification - callers build that context, this class just
    # passes it straight through to the underlying `HTTP::Client`).
    #
    # - tls_hostname: overrides which hostname the TLS handshake verifies
    #   the server's certificate against, independent of *host* (which is
    #   still what's actually connected to) - the common
    #   docker-machine-style setup of reaching a daemon via a raw IP while
    #   its certificate was issued for a fixed name like "localhost".
    #   `nil` (the default) verifies against *host* itself, matching plain
    #   `HTTP::Client`'s own behavior.
    def initialize(host : String, port : Int32, tls : HTTP::Client::TLSContext = nil, tls_hostname : String? = nil)
      super(host: host, port: port, tls: tls)
      @socket_path = nil
      @tls_hostname = tls_hostname
    end

    private def docker_host_socket_path : String?
      ENV["DOCKER_HOST"]?.try(&.sub(/^unix:\/\//, ""))
    end

    # Lazily (re)connect over a UNIX socket instead of HTTP::Client's own
    # TCP/TLS logic - otherwise identical to how HTTP::Client#io works.
    # When constructed for a remote TCP(+TLS) daemon instead (no
    # @socket_path set), defers to HTTP::Client's own #io unchanged via
    # `super` UNLESS @tls_hostname overrides the verification hostname
    # (HTTP::Client's own #io always verifies against @host, with no way
    # to override just that - see #io_with_tls_hostname_override below
    # for the one case this reimplements instead of delegating).
    private def io
      if socket_path = @socket_path
        return io_unix(socket_path)
      end

      return super unless @tls_hostname

      io_with_tls_hostname_override
    end

    private def io_unix(socket_path : String)
      cached = @io
      return cached if cached
      unless @reconnect
        raise "This HTTP::Client cannot be reconnected"
      end

      socket = UNIXSocket.new(socket_path)
      socket.read_timeout = @read_timeout if @read_timeout
      socket.write_timeout = @write_timeout if @write_timeout
      socket.sync = false

      @io = socket
    end

    # Identical to HTTP::Client's own private #io, except the TLS
    # handshake verifies the server's certificate against @tls_hostname
    # instead of unconditionally using @host - the one thing plain
    # `HTTP::Client` has no hook for at all, hence reimplementing this
    # rather than delegating via `super`.
    private def io_with_tls_hostname_override
      cached = @io
      return cached if cached
      unless @reconnect
        raise "This HTTP::Client cannot be reconnected"
      end

      hostname = @host.starts_with?('[') && @host.ends_with?(']') ? @host[1..-2] : @host
      socket = TCPSocket.new(hostname, @port, @dns_timeout, @connect_timeout)
      socket.read_timeout = @read_timeout if @read_timeout
      socket.write_timeout = @write_timeout if @write_timeout
      socket.sync = false

      if tls = @tls
        tcp_socket = socket
        begin
          socket = OpenSSL::SSL::Socket::Client.new(tcp_socket, context: tls, sync_close: true, hostname: @tls_hostname)
        rescue exc
          tcp_socket.close
          raise exc
        end
      end

      @io = socket
    end

    # Performs one request and returns the completed response.
    #
    # Never raises for a non-2xx status: the status code, reason phrase, raw
    # body and request URL all come back on the Response, so a caller that
    # wants its own error wording (the Docker Python SDK's APIError, say) has
    # everything it needs without a second round trip.
    #
    # The body is always read to EOF so the shared keep-alive connection's
    # framing stays in sync; endpoint wrappers parse the returned String.
    def request(method : String, url : String, headers : HTTP::Headers? = nil, body : String? = nil) : KrikriDocker::Response
      status = 0
      reason = ""
      body_text = ""
      exec(method, url, headers, body) do |response|
        status = response.status_code
        sent_reason = response.status_message
        reason = sent_reason && !sent_reason.empty? ? sent_reason : KrikriDocker::Response.reason_phrase(status)
        body_text = response.body_io?.try(&.gets_to_end) || ""
      end
      KrikriDocker::Response.new(status, reason, body_text, url)
    end

    # Like #request, but raises Errors::DockerAPIError for a non-2xx status
    # and yields the Response to the caller otherwise.
    def call(method : String, url : String, headers : HTTP::Headers? = nil, body : String? = nil, &)
      response = request(method, url, headers, body)
      raise Errors::DockerAPIError.new(response) unless response.success?
      yield response
    end

    # The daemon's API version, negotiated once per client.
    #
    # The Docker Python SDK prefixes every endpoint URL with it, and its
    # APIError wording quotes that versioned URL; caching it here keeps the
    # extra /version round trip off every subsequent rendering instead of
    # asking again per failure.
    def api_version : String
      @api_version ||= begin
        version = ""
        call("GET", "/version") do |response|
          version = JSON.parse(response.body)["ApiVersion"].as_s
        end
        version
      end
    end
  end
end
