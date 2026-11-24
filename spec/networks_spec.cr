require "./spec_helper"

describe "Networks" do
  it "lists, creates, inspects and deletes a network" do
    next unless docker_available?

    client = KrikriDocker::Client.new
    api = KrikriDocker::API.new(client)

    config = KrikriDocker::Types::NetworkConfig.new("krikri-docker-spec-net")
    created = api.networks.create(config)

    found = api.networks.list.find(&.name.==("krikri-docker-spec-net"))
    found.should_not be_nil

    inspected = api.networks.inspect(created.id)
    inspected.id.should eq created.id

    json = api.networks.get_json(created.id)
    json["Id"].as_s.should eq created.id

    api.networks.delete(created.id)
    api.networks.list.any?(&.name.==("krikri-docker-spec-net")).should be_false
  end
end
