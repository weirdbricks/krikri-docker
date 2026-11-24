require "./test_helper"

describe KrikriDocker::URL do
  it "form-encodes like Python's urlencode" do
    KrikriDocker::URL.form_encode("docker.io/library/busybox").must_equal("docker.io%2Flibrary%2Fbusybox")
    KrikriDocker::URL.form_encode("a b-c.d_e~f").must_equal("a+b-c.d_e~f")
    KrikriDocker::URL.form_encode(%({"name":["a*"]})).must_equal("%7B%22name%22%3A%5B%22a%2A%22%5D%7D")
  end

  it "path-encodes like quote(value, safe='/:'))" do
    KrikriDocker::URL.path_segment("alpine@sha256:abc").must_equal("alpine%40sha256:abc")
    KrikriDocker::URL.path_segment("my net").must_equal("my%20net")
    KrikriDocker::URL.path_segment("a/b:c.d_e-f~g").must_equal("a/b:c.d_e-f~g")
  end

  it "spells booleans the Python way" do
    KrikriDocker::URL.python_bool(true).must_equal("True")
    KrikriDocker::URL.python_bool(false).must_equal("False")
  end
end

describe KrikriDocker::Errors::DockerAPIError do
  it "extracts a string message" do
    KrikriDocker::Errors::DockerAPIError.daemon_message(%({"message": "no such network"})).must_equal("no such network")
  end

  it "renders a non-string scalar message the way an f-string would" do
    KrikriDocker::Errors::DockerAPIError.daemon_message(%({"message": 123})).must_equal("123")
  end

  it "returns the raw body for a non-JSON body" do
    KrikriDocker::Errors::DockerAPIError.daemon_message("Not Found").must_equal("Not Found")
  end

  it "is nil for an empty body" do
    KrikriDocker::Errors::DockerAPIError.daemon_message("").must_be_nil
  end
end

describe KrikriDocker::Response do
  it "uses canonical reason phrases for the codes a daemon answers with" do
    KrikriDocker::Response.reason_phrase(500).must_equal("Internal Server Error")
    KrikriDocker::Response.reason_phrase(404).must_equal("Not Found")
  end

  it "is empty for an unknown code" do
    KrikriDocker::Response.reason_phrase(999).must_equal("")
  end
end
