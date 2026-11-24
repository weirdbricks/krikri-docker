require "./spec_helper"

describe "Containers" do
  it "lists, creates, inspects, starts, stops and deletes a container" do
    next unless docker_available?

    client = KrikriDocker::Client.new
    api = KrikriDocker::API.new(client)
    api.images.pull("alpine", "latest")

    config = KrikriDocker::Types::CreateContainerConfig.new(
      image: "alpine:latest",
      cmd: ["sleep", "60"],
      host_config: KrikriDocker::Types::HostConfig.new,
    )

    created = api.containers.create("krikri-docker-spec", config)
    api.containers.start(created.id)

    inspected = api.containers.inspect(created.id)
    inspected.config.cmd.should eq ["sleep", "60"]

    json = api.containers.inspect_json(created.id)
    json["Id"].as_s.should eq created.id

    found = api.containers.list(all: true).find(&.names.map(&.lchop('/')).includes?("krikri-docker-spec"))
    found.should_not be_nil
    found.try(&.state).should eq "running"

    api.containers.stop(created.id)
    api.containers.delete(created.id, force: true)

    api.containers.list(all: true).any?(&.names.map(&.lchop('/')).includes?("krikri-docker-spec")).should be_false
  end
end
