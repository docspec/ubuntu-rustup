# ubuntu-rustup

A public Ubuntu 24.04 container image for ephemeral GitHub Actions Runner
Controller (ARC) runners. It extends GitHub's official ARC runner image with:

- Rustup 1.29.0, installed without a default Rust toolchain so each repository's
  `rust-toolchain.toml` remains authoritative.
- `build-essential` and `pkg-config` for crates with native build dependencies.
- `git-lfs`, so `actions/checkout` with `lfs: true` works on the runner itself.
- Docker CLI 29.7.2, Buildx 0.36.1, and Compose 5.5.0 for use with an external
  Docker daemon such as ARC's disposable Docker-in-Docker sidecar.

The image runs as the upstream `runner` user. Docker daemon binaries are not
included; a Docker daemon must be supplied separately when workflows need one.

## Pull

```bash
docker pull ghcr.io/docspec/ubuntu-rustup:24.04
```

Release tags are immutable. `24.04` and `latest` are moving aliases for the
newest published Ubuntu 24.04 release. Deployments should pin the multi-platform
digest of a release tag.

## Platforms

- `linux/amd64`
- `linux/arm64`

## Build locally

```bash
docker buildx build --load --tag ubuntu-rustup:local .
```

The build verifies checksums for downloaded Rustup and Compose binaries. Base
images and GitHub Actions are pinned by digest or commit SHA and updated through
reviewed dependency updates.
