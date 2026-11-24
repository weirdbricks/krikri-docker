require "./client"
require "./endpoints/*"

module KrikriDocker
  # The Docker Engine API, one endpoint handler per resource.
  class API
    # The client instance used for making API requests.
    getter client : Client

    getter images : Endpoints::Images
    getter containers : Endpoints::Containers
    getter networks : Endpoints::Networks
    getter volumes : Endpoints::Volumes
    getter sys : Endpoints::System

    def initialize(@client)
      @images = Endpoints::Images.new(client)
      @containers = Endpoints::Containers.new(client)
      @networks = Endpoints::Networks.new(client)
      @volumes = Endpoints::Volumes.new(client)
      @sys = Endpoints::System.new(client)
    end
  end
end
