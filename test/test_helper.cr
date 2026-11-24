require "minitest/autorun"

require "../src/krikri-docker"
require "../src/krikri_docker/types/*"

# The transport tests need a daemon; the default socket is the Docker CLI's
# own (podman's compat socket included when it is linked there).
SOCKET_PATH = ENV["DOCKER_HOST"]?.try(&.sub(/^unix:\/\//, "")) || KrikriDocker::Client::DEFAULT_SOCKET_PATH

def docker_available? : Bool
  File.info(SOCKET_PATH).type.socket?
rescue File::NotFoundError
  false
end
