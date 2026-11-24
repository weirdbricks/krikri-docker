module KrikriDocker
  # Encoding helpers shared by the endpoints. Each one reproduces the Docker
  # Python SDK's own URL construction byte for byte, because Ansible quotes
  # these URLs in a failed request's message.
  module URL
    # Python's requests form-encodes query values like urlencode: everything
    # outside the unreserved set percent-encoded, space as '+', so a `/` in a
    # repository name becomes %2F exactly like the SDK's own pull URL.
    def self.form_encode(value : String) : String
      String.build do |io|
        value.each_byte do |byte|
          char = byte.chr
          if char.ascii_alphanumeric? || "-._~".includes?(char)
            io << char
          elsif char == ' '
            io << '+'
          else
            io << '%' << byte.to_s(16).upcase.rjust(2, '0')
          end
        end
      end
    end

    # Python's quote(value, safe="/:") - what the SDK's `_url` applies to
    # every path argument. Keeps unreserved characters plus `/` and `:` so a
    # digest reference becomes `name@sha256` -> `name%40sha256`, and a name
    # with a space cannot produce a malformed request line.
    def self.path_segment(value : String) : String
      String.build do |io|
        value.each_byte do |byte|
          char = byte.chr
          if char.ascii_alphanumeric? || "-._~/:".includes?(char)
            io << char
          else
            io << '%' << byte.to_s(16).upcase.rjust(2, '0')
          end
        end
      end
    end

    # Python's str(bool), the spelling requests puts in a query string built
    # from a bool parameter ("force=True", not "force=true").
    def self.python_bool(value : Bool) : String
      value ? "True" : "False"
    end
  end
end
