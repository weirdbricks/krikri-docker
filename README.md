# krikri-docker

Docker Engine API client for Crystal.

This is a trimmed fork of [marghidanu/docr](https://github.com/marghidanu/docr)
(MIT), maintained by the [krikri](https://github.com/weirdbricks/krikri)
project. It carries the Docker/Podman compatibility fixes the fork needed and
keeps only the API surface krikri uses, so the shard stays small enough to
audit and to release on krikri's own cadence.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     krikri-docker:
       github: weirdbricks/krikri-docker
       tag: v0.1.0
   ```

2. Run `shards install`

## Usage

```crystal
require "krikri_docker"

client = KrikriDocker::Client.new                       # /var/run/docker.sock or DOCKER_HOST
api = KrikriDocker::API.new(client)

api.containers.list
```

A remote daemon takes the TCP constructor, optionally with TLS:

```crystal
client = KrikriDocker::Client.new("docker.example.com", 2376, tls_context)
```

## Supported API calls

### Containers

* [x] ContainerList
* [x] ContainerCreate
* [x] ContainerInspect
* [x] ContainerStart
* [x] ContainerStop
* [x] ContainerDelete

### Images

* [x] ImageCreate (pull)
* [x] ImageInspect
* [x] ImageDelete

### Networks

* [x] NetworkList
* [x] NetworkCreate
* [x] NetworkInspect
* [x] NetworkConnect
* [x] NetworkDisconnect
* [x] NetworkDelete

### Volumes

* [x] VolumeList
* [x] VolumeCreate
* [x] VolumeInspect
* [x] VolumeDelete

### System

* [x] SystemAuth
* [x] SystemVersion

## Differences from upstream docr

- Module/namespace renamed `Docr` -> `KrikriDocker` (so both trees can be
  installed side by side).
- Failures carry the request URL, status code, reason phrase and raw body, and
  the negotiated API version is cached per client, so callers can render the
  Docker Python SDK's `APIError` wording without a second round trip.
- `DOCKER_HOST` support, reconnect handling, TCP/TLS with a `tls_hostname`
  override, and the nullable/newer-Engine response shapes (`Health.Log`,
  `LogConfig.Config`, a missing `GraphDriver`).
- Everything upstream has that krikri does not use (exec, build, push, tag,
  logs, events, system info, changes, top, waits, pauses, restart/kill, image
  history) is gone.

## Contributors

- [Tudor Marghidanu](https://github.com/marghidanu) - creator and maintainer of
  upstream docr
- [Troy Sornson](https://github.com/Vici37) - upstream contributor
- Krikri Contributors - fork maintenance
