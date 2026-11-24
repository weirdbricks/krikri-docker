require "./test_helper"

describe "Containers" do
  it "lists, creates, inspects, starts, stops and deletes a container" do
    skip("no Docker-API socket at #{SOCKET_PATH}") unless docker_available?

    client = KrikriDocker::Client.new
    api = KrikriDocker::API.new(client)
    api.images.pull("alpine", "latest")

    config = KrikriDocker::Types::CreateContainerConfig.new(
      image: "alpine:latest",
      cmd: ["sleep", "60"],
      host_config: KrikriDocker::Types::HostConfig.new,
    )

    created = api.containers.create("krikri-docker-test", config)
    api.containers.start(created.id)

    inspected = api.containers.inspect(created.id)
    inspected.config.cmd.must_equal(["sleep", "60"])

    json = api.containers.inspect_json(created.id)
    json["Id"].as_s.must_equal(created.id)

    found = api.containers.list(all: true).find(&.names.map(&.lchop('/')).includes?("krikri-docker-test"))
    found.wont_be_nil
    found.not_nil!.state.must_equal("running")

    api.containers.stop(created.id)
    api.containers.delete(created.id, force: true)

    api.containers.list(all: true).any?(&.names.map(&.lchop('/')).includes?("krikri-docker-test")).must_equal(false)
  end
end
