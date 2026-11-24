require "./spec_helper"

describe "System" do
  it "reports a version and caches the negotiated API version" do
    next unless docker_available?

    client = KrikriDocker::Client.new
    api = KrikriDocker::API.new(client)

    version = api.sys.version
    version.version.should_not be_empty
    version.api_version.should_not be_empty

    client.api_version.should eq version.api_version
  end
end
