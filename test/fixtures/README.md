# Response fixtures

Captured responses the parser specs run against, one directory per engine.

- `podman-5.4.2/` - real captures from Podman 5.4.2's Docker-compatible API
  (`podman system service`, API 1.41), taken with a `busybox:latest`
  container, a `krikri-fixture-net` bridge network and a
  `krikri-fixture-vol` volume. The body is the daemon's own, unmodified.

Docker Engine captures (29.x/30.x, where the inspect payload omits
`GraphDriver` and a fresh container reports `Health.Log: null` and
`LogConfig.Config: null`) need a host running that engine; add a
`docker-<version>/` directory from such a host. The null/missing-field cases
those engines hit are also exercised directly in `test/types_test.cr`, so the
parsers stay covered in the meantime.
