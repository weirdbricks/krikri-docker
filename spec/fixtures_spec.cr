require "./spec_helper"

# Asserts that the daemon payloads captured under spec/fixtures/ parse into
# the models krikri reads fields from. These are the regression net for the
# response shapes: a field rename or a tightened nullability shows up here
# without needing a live daemon.
FIXTURES = File.join(__DIR__, "fixtures", "podman-5.4.2")

def fixture(name : String) : String
  File.read(File.join(FIXTURES, name))
end

describe "response fixtures (podman 5.4.2)" do
  it "parses the version response and exposes the API version" do
    version = KrikriDocker::Types::SystemVersion.from_json(fixture("version.json"))
    version.api_version.should eq "1.41"
    version.version.should_not be_empty
  end

  it "parses a container listing" do
    summaries = Array(KrikriDocker::Types::ContainerSummary).from_json(fixture("containers_list.json"))
    summary = summaries.find { |entry| entry.names.includes?("/krikri-fixture-ctr") }
    summary.should_not be_nil
    summary.not_nil!.image.should contain "busybox:latest"
    summary.not_nil!.state.should eq "created"
  end

  it "parses a container inspect response into the fields a comparison reads" do
    inspect = KrikriDocker::Types::ContainerInspectResponse.from_json(fixture("container_inspect.json"))

    inspect.config.image.not_nil!.should contain "busybox:latest"
    inspect.config.cmd.should eq ["sleep", "120"]
    inspect.config.env.should_not be_nil
    inspect.host_config.binds.not_nil!.first.should start_with "/tmp:/tmp"
    inspect.host_config.network_mode.should eq "bridge"
    inspect.host_config.privileged.should be_false
    inspect.host_config.port_bindings.should eq({} of String => Array(KrikriDocker::Types::PortBinding))
    inspect.host_config.restart_policy.try(&.name).should_not be_nil
    inspect.network_settings.networks.keys.should_not be_empty
  end

  it "parses an image inspect response" do
    image = KrikriDocker::Types::Image.from_json(fixture("image_inspect.json"))
    image.id.should start_with "sha256:"
    image.config.cmd.should_not be_nil
  end

  it "parses the network listing and a network inspect response" do
    networks = Array(KrikriDocker::Types::Network).from_json(fixture("networks_list.json"))
    networks.should_not be_empty

    network = KrikriDocker::Types::Network.from_json(fixture("network_inspect.json"))
    network.name.should eq "krikri-fixture-net"
    network.driver.should eq "bridge"
    network.id.should_not be_empty
  end

  it "parses the volume listing and a volume create response" do
    listing = JSON.parse(fixture("volumes_list.json"))
    volumes = listing["Volumes"].as_a
    volumes.any? { |volume| volume["Name"].as_s == "krikri-fixture-vol" }.should be_true

    created = JSON.parse(fixture("volume_create.json"))
    created["Name"].as_s.should eq "krikri-fixture-vol"
    created["Driver"].as_s.should eq "local"
  end

  it "recovers the daemon message from a JSON error body" do
    body = fixture("error_404.json")
    KrikriDocker::Errors::DockerAPIError.daemon_message(body)
      .should contain("no container with name or ID")
  end

  it "falls back to the raw body for a non-JSON error body" do
    KrikriDocker::Errors::DockerAPIError.daemon_message("Not Found").should eq "Not Found"
  end
end
