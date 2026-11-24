require "json"

module KrikriDocker::Types
  # The HostConfig fields this client reads (container idempotency
  # comparison) and sends (container creation).
  class HostConfig
    include JSON::Serializable

    @[JSON::Field(key: "Binds")]
    property binds : Array(String)?

    @[JSON::Field(key: "NetworkMode")]
    property network_mode : String?

    @[JSON::Field(key: "PortBindings")]
    property port_bindings : Hash(String, Array(KrikriDocker::Types::PortBinding))?

    @[JSON::Field(key: "RestartPolicy")]
    property restart_policy : KrikriDocker::Types::RestartPolicy?

    @[JSON::Field(key: "AutoRemove")]
    property auto_remove : Bool?

    @[JSON::Field(key: "Memory")]
    property memory : Int64?

    @[JSON::Field(key: "MemoryReservation")]
    property memory_reservation : Int64?

    @[JSON::Field(key: "MemorySwap")]
    property memory_swap : Int64?

    @[JSON::Field(key: "MemorySwappiness")]
    property memory_swappiness : Int64?

    @[JSON::Field(key: "NanoCpus")]
    property nano_cpus : Int64?

    @[JSON::Field(key: "CpuShares")]
    property cpu_shares : Int64?

    @[JSON::Field(key: "CpusetCpus")]
    property cpuset_cpus : String?

    @[JSON::Field(key: "CpusetMems")]
    property cpuset_mems : String?

    @[JSON::Field(key: "PidsLimit")]
    property pids_limit : Int64?

    @[JSON::Field(key: "OomScoreAdj")]
    property oom_score_adj : Int64?

    @[JSON::Field(key: "OomKillDisable")]
    property oom_kill_disable : Bool?

    @[JSON::Field(key: "Privileged")]
    property privileged : Bool?

    def initialize(
      @binds = nil,
      @network_mode = nil,
      @port_bindings = nil,
      @restart_policy = nil,
      @auto_remove = nil,
      @memory = nil,
      @memory_reservation = nil,
      @memory_swap = nil,
      @memory_swappiness = nil,
      @nano_cpus = nil,
      @cpu_shares = nil,
      @cpuset_cpus = nil,
      @cpuset_mems = nil,
      @pids_limit = nil,
      @oom_score_adj = nil,
      @oom_kill_disable = nil,
      @privileged = nil,
    )
    end
  end
end
