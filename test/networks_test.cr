require "./test_helper"

describe "Networks" do
  it "lists, creates, inspects and deletes a network" do
    skip("no Docker-API socket at #{SOCKET_PATH}") unless docker_available?

    api = KrikriDocker::API.new(KrikriDocker::Client.new)

    config = KrikriDocker::Types::NetworkConfig.new("krikri-docker-test-net")
    created = api.networks.create(config)

    api.networks.list.find(&.name.==("krikri-docker-test-net")).wont_be_nil

    inspected = api.networks.inspect(created.id)
    inspected.id.must_equal(created.id)

    json = api.networks.get_json(created.id)
    json["Id"].as_s.must_equal(created.id)

    api.networks.delete(created.id)
    api.networks.list.any?(&.name.==("krikri-docker-test-net")).must_equal(false)
  end
end
