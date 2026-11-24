require "socket"
require "random/secure"

# A one-shot fake daemon for request-shape tests: accepts one connection per
# canned response, records the request line and headers, then answers with
# `Connection: close` so every request is a fresh connection (which is also
# what makes it usable for multi-call tests like the API-version cache).
class StubDocker
  getter socket_path : String
  getter request_lines = [] of String
  getter request_headers = [] of HTTP::Headers

  def initialize(@responses : Array({String, String}))
    @socket_path = File.join(Dir.tempdir, "krikri-docker-stub-#{Random::Secure.hex(6)}.sock")
    @server = UNIXServer.new(@socket_path)
  end

  def serve(&)
    done = Channel(Nil).new
    spawn do
      @responses.each do |(status, body)|
        socket = @server.accept
        line, headers = read_request(socket)
        @request_lines << line
        @request_headers << headers
        socket << "HTTP/1.1 #{status}\r\n"
        socket << "Content-Type: application/json\r\n"
        socket << "Content-Length: #{body.bytesize}\r\n"
        socket << "Connection: close\r\n\r\n"
        socket << body
        socket.flush
        socket.close
      end
    rescue
      # The test stopped early; the failed assertion is the real report.
    ensure
      done.send(nil) rescue nil
    end

    begin
      yield self
    ensure
      select
      when done.receive
      when timeout(2.seconds)
      end
      @server.close
      File.delete(@socket_path) if File.exists?(@socket_path)
    end
  end

  private def read_request(socket : UNIXSocket) : {String, HTTP::Headers}
    line = (socket.gets('\n') || "").chomp
    headers = HTTP::Headers.new
    while raw = socket.gets('\n')
      header = raw.chomp
      break if header.empty?
      name, _, value = header.partition(':')
      headers[name.strip] = value.strip
    end
    if (raw_length = headers["Content-Length"]?) && (length = raw_length.to_i?) && length > 0
      socket.read_fully(Bytes.new(length))
    end
    {line, headers}
  end
end
