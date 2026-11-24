require "./spec_helper"

describe "Images" do
  it "pulls, inspects and deletes an image" do
    next unless docker_available?

    client = KrikriDocker::Client.new
    api = KrikriDocker::API.new(client)

    api.images.pull("alpine", "latest")

    inspected = api.images.inspect("alpine:latest")
    inspected.id.should start_with "sha256:"

    json = api.images.inspect_json("alpine:latest")
    json["Id"].as_s.should eq inspected.id

    api.images.delete("alpine:latest", force: true)
  end

  it "raises DockerAPIError carrying the pull URL for an unparseable reference" do
    next unless docker_available?

    api = KrikriDocker::API.new(KrikriDocker::Client.new)
    error = expect_raises(KrikriDocker::Errors::DockerAPIError) do
      api.images.pull("not a valid reference", "latest")
    end
    error.url.should eq "/images/create?tag=latest&fromImage=not+a+valid+reference"
    error.status_code.should eq 500
    error.reason.should_not be_empty
  end
end
