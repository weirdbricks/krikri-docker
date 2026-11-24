require "./test_helper"

describe "Images" do
  it "pulls, inspects and deletes an image" do
    skip("no Docker-API socket at #{SOCKET_PATH}") unless docker_available?

    api = KrikriDocker::API.new(KrikriDocker::Client.new)

    api.images.pull("alpine", "latest")

    inspected = api.images.inspect("alpine:latest")
    inspected.id.must_match(/^sha256:/)

    json = api.images.inspect_json("alpine:latest")
    json["Id"].as_s.must_equal(inspected.id)

    api.images.delete("alpine:latest", force: true)
  end

  it "raises DockerAPIError carrying the pull URL for an unparseable reference" do
    skip("no Docker-API socket at #{SOCKET_PATH}") unless docker_available?

    api = KrikriDocker::API.new(KrikriDocker::Client.new)
    error = assert_raises(KrikriDocker::Errors::DockerAPIError) do
      api.images.pull("not a valid reference", "latest")
    end
    error.url.must_equal("/images/create?tag=latest&fromImage=not+a+valid+reference")
    (400..599).includes?(error.status_code).must_equal(true)
    error.reason.wont_be_empty
  end
end
