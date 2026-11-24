require "./test_helper"

# Asserts that the daemon payloads captured under test/fixtures/ parse into
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
    version.api_version.must_equal("1.41")
    version.version.wont_be_empty
  end

  it "parses a container listing" do
    summaries = Array(KrikriDocker::Types::ContainerSummary).from_json(fixture("containers_list.json"))
    summary = summaries.find(&.names.includes?("/krikri-fixture-ctr"))
    summary.wont_be_nil
    summary.not_nil!.image.must_include("busybox:latest")
    summary.not_nil!.state.must_equal("created")
  end

  it "parses a container inspect response into the fields a comparison reads" do
    inspect = KrikriDocker::Types::ContainerInspectResponse.from_json(fixture("container_inspect.json"))

    inspect.config.image.not_nil!.must_include("busybox:latest")
    inspect.config.cmd.must_equal(["sleep", "120"])
    inspect.config.env.wont_be_nil
    inspect.host_config.binds.not_nil!.first.must_match(/^\/tmp:\/tmp/)
    inspect.host_config.network_mode.must_equal("bridge")
    inspect.host_config.privileged.must_equal(false)
    inspect.host_config.port_bindings.must_equal({} of String => Array(KrikriDocker::Types::PortBinding))
    inspect.host_config.restart_policy.try(&.name).wont_be_nil
    inspect.network_settings.networks.keys.wont_be_empty
  end

  it "parses an image inspect response" do
    image = KrikriDocker::Types::Image.from_json(fixture("image_inspect.json"))
    image.id.must_match(/^sha256:/)
    image.config.try(&.cmd).wont_be_nil
  end

  it "parses the network listing and a network inspect response" do
    Array(KrikriDocker::Types::Network).from_json(fixture("networks_list.json")).wont_be_empty

    network = KrikriDocker::Types::Network.from_json(fixture("network_inspect.json"))
    network.name.must_equal("krikri-fixture-net")
    network.driver.must_equal("bridge")
    network.id.wont_be_empty
  end

  it "parses the volume listing and a volume create response" do
    listing = JSON.parse(fixture("volumes_list.json"))
    volumes = listing["Volumes"].as_a
    volumes.any? { |volume| volume["Name"].as_s == "krikri-fixture-vol" }.must_equal(true)

    created = JSON.parse(fixture("volume_create.json"))
    created["Name"].as_s.must_equal("krikri-fixture-vol")
    created["Driver"].as_s.must_equal("local")
  end

  it "recovers the daemon message from a JSON error body" do
    KrikriDocker::Errors::DockerAPIError.daemon_message(fixture("error_404.json"))
      .not_nil!.must_include("no container with name or ID")
  end

  it "falls back to the raw body for a non-JSON error body" do
    KrikriDocker::Errors::DockerAPIError.daemon_message("Not Found").must_equal("Not Found")
  end
end
