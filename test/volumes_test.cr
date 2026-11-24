require "./test_helper"

describe "Volumes" do
  it "lists, creates, inspects and removes a volume" do
    skip("no Docker-API socket at #{SOCKET_PATH}") unless docker_available?

    api = KrikriDocker::API.new(KrikriDocker::Client.new)

    api.volumes.create("krikri-docker-test-vol")

    listing = api.volumes.list_json
    listing["Volumes"].as_a.any?(&.["Name"].as_s.==("krikri-docker-test-vol")).must_equal(true)

    volume = api.volumes.get_json("krikri-docker-test-vol")
    volume.wont_be_nil
    volume.not_nil!["Name"].as_s.must_equal("krikri-docker-test-vol")

    api.volumes.remove("krikri-docker-test-vol")
    api.volumes.get_json("krikri-docker-test-vol").must_be_nil
  end
end
