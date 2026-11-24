require "./spec_helper"

describe "Volumes" do
  it "lists, creates, inspects and removes a volume" do
    next unless docker_available?

    client = KrikriDocker::Client.new
    api = KrikriDocker::API.new(client)

    api.volumes.create("krikri-docker-spec-vol")

    listing = api.volumes.list_json
    listing["Volumes"].as_a.any?(&.["Name"].as_s.==("krikri-docker-spec-vol")).should be_true

    volume = api.volumes.get_json("krikri-docker-spec-vol")
    volume.should_not be_nil
    volume.try(&.["Name"].as_s).should eq "krikri-docker-spec-vol"

    api.volumes.remove("krikri-docker-spec-vol")
    api.volumes.get_json("krikri-docker-spec-vol").should be_nil
  end
end
