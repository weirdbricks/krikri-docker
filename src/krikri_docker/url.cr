module KrikriDocker
  # Query-value encoding shared by the endpoints that must match the Docker
  # Python SDK's own URL construction byte for byte.
  module URL
    # Python's requests form-encodes query values like urlencode: everything
    # outside the unreserved set percent-encoded, so a `/` in a repository
    # name becomes %2F exactly like the SDK's own pull URL.
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
  end
end
