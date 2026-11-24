require "./test_helper"

describe KrikriDocker::Types do
  it "parses a minimal container inspect response" do
    json = <<-JSON
      {
        "Id": "abc",
        "Config": {"Cmd": ["run"], "Env": ["A=1"], "Labels": {"l": "v"}},
        "HostConfig": {"Binds": ["/a:/b"], "Privileged": false},
        "NetworkSettings": {"Networks": {"bridge": {"Gateway": "172.17.0.1"}}}
      }
      JSON

    inspect = KrikriDocker::Types::ContainerInspectResponse.from_json(json)
    inspect.config.cmd.must_equal(["run"])
    inspect.config.env.must_equal(["A=1"])
    inspect.host_config.binds.must_equal(["/a:/b"])
    inspect.network_settings.networks.keys.must_equal(["bridge"])
  end

  it "parses a network with a null Containers list and null IPAM" do
    json = %({"Name": "bridge", "Id": "id", "Driver": "bridge", "IPAM": null, "Containers": null})

    network = KrikriDocker::Types::Network.from_json(json)
    network.ipam.must_be_nil
    network.containers.must_be_nil
  end

  it "parses a container summary with a created state" do
    json = %([{"Id": "id", "Names": ["/c"], "Image": "alpine", "State": "created"}])

    summaries = Array(KrikriDocker::Types::ContainerSummary).from_json(json)
    summaries.first.state.must_equal("created")
  end
end
