require "./test_helper"

describe "System" do
  it "reports a version and caches the negotiated API version" do
    skip("no Docker-API socket at #{SOCKET_PATH}") unless docker_available?

    client = KrikriDocker::Client.new
    api = KrikriDocker::API.new(client)

    version = api.sys.version
    version.version.wont_be_empty
    version.api_version.wont_be_empty

    client.api_version.must_equal(version.api_version)
  end
end
