require "./test_helper"
require "./stub_docker"

describe "request shapes" do
  it "builds the SDK's container list query" do
    stub = StubDocker.new([{"200 OK", "[]"}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.containers.list(all: true).must_be_empty
    end
    stub.request_lines.first.must_equal("GET /containers/json?limit=-1&all=1&size=0&trunc_cmd=0 HTTP/1.1")
  end

  it "appends an encoded filters parameter only when filters are given" do
    stub = StubDocker.new([{"200 OK", "[]"}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.containers.list(all: true, filters: {"name" => ["a b"]})
    end
    stub.request_lines.first.must_equal(
      "GET /containers/json?limit=-1&all=1&size=0&trunc_cmd=0&filters=%7B%22name%22%3A%5B%22a+b%22%5D%7D HTTP/1.1")
  end

  it "builds the SDK's container delete query" do
    stub = StubDocker.new([{"204 No Content", ""}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.containers.delete("abc", force: true)
    end
    stub.request_lines.first.must_equal("DELETE /containers/abc?v=False&link=False&force=True HTTP/1.1")
  end

  it "percent-encodes path segments" do
    stub = StubDocker.new([{"200 OK", %({"Id": "x"})}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.images.inspect_json("alpine@sha256:abc")
    end
    stub.request_lines.first.must_equal("GET /images/alpine%40sha256:abc/json HTTP/1.1")
  end

  it "sends only force on an image delete" do
    stub = StubDocker.new([{"200 OK", "[]"}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.images.delete("alpine:latest", force: true)
    end
    stub.request_lines.first.must_equal("DELETE /images/alpine:latest?force=True HTTP/1.1")
  end

  it "sends no query on a volume delete" do
    stub = StubDocker.new([{"204 No Content", ""}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.volumes.remove("my-vol")
    end
    stub.request_lines.first.must_equal("DELETE /volumes/my-vol HTTP/1.1")
  end

  it "percent-encodes a network name on connect" do
    stub = StubDocker.new([{"200 OK", "{}"}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.networks.connect("my net", "abc")
    end
    stub.request_lines.first.must_equal("POST /networks/my%20net/connect HTTP/1.1")
  end

  it "carries the request URL, status, reason and body on an API error" do
    stub = StubDocker.new([{"404 Not Found", %({"message": "no such container"})}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      error = assert_raises(KrikriDocker::Errors::DockerAPIError) { api.containers.inspect("nope") }
      error.status_code.must_equal(404)
      error.reason.must_equal("Not Found")
      error.url.must_equal("/containers/nope/json")
      error.body.must_equal(%({"message": "no such container"}))
      error.daemon_message.must_equal("no such container")
    end
  end

  it "raises ImagePullError for an error line in a 200 pull stream" do
    stream = %({"status":"Pulling from library/x"}\n{"errorDetail":{"code":1,"message":"denied"},"error":"denied"}\n)
    stub = StubDocker.new([{"200 OK", stream}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      error = assert_raises(KrikriDocker::Errors::ImagePullError) { api.images.pull("x", "latest") }
      error.error.must_equal("denied")
      error.code.must_equal("1")
      error.message.must_equal("denied")
    end
  end

  it "sends X-Registry-Auth and the platform parameter on a pull" do
    stub = StubDocker.new([{"200 OK", %({"status":"ok"})}])
    stub.serve do |server|
      api = KrikriDocker::API.new(KrikriDocker::Client.new(server.socket_path))
      api.images.pull("repo", "tag", registry_auth: "creds", platform: "linux/amd64")
    end
    stub.request_lines.first.must_equal(
      "POST /images/create?tag=tag&fromImage=repo&platform=linux%2Famd64 HTTP/1.1")
    stub.request_headers.first["X-Registry-Auth"].must_equal("creds")
  end

  it "negotiates the API version once per client" do
    stub = StubDocker.new([{"200 OK", %({"ApiVersion": "1.41"})}])
    stub.serve do |server|
      client = KrikriDocker::Client.new(server.socket_path)
      client.api_version.must_equal("1.41")
      client.api_version.must_equal("1.41")
    end
    stub.request_lines.size.must_equal(1)
    stub.request_lines.first.must_equal("GET /version HTTP/1.1")
  end

  it "reports a /version reply without ApiVersion with the SDK's text" do
    stub = StubDocker.new([{"200 OK", %({"Version": "29.0.0"})}])
    stub.serve do |server|
      client = KrikriDocker::Client.new(server.socket_path)
      error = assert_raises(KrikriDocker::Errors::InvalidVersionError) { client.api_version }
      error.message.must_equal(%(Invalid response from docker daemon: key "ApiVersion" is missing.))
    end
  end
end
