# ubuntu-rustup

A public Ubuntu 24.04 container image for ephemeral GitHub Actions Runner
Controller (ARC) runners. It extends GitHub's official ARC runner image with:

- Rustup 1.29.0 with the stable toolchain (`minimal` profile plus `clippy` and
  `rustfmt`) preinstalled as the default, so `rustup toolchain install stable`
  finds it and downloads nothing. A repository's `rust-toolchain.toml` still
  wins; other toolchains install at job time as usual. `RUSTUP_HOME` is
  `/opt/rustup`, outside `/home/runner`, because ARC's Kubernetes container hook
  copies `/home/runner` into every job Pod. `CARGO_HOME` stays
  `/home/runner/.cargo`.
- GitHub CLI (`gh`) 2.103.3.
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

Release tags are immutable. Besides manually pushed `v*` tags, a weekly
scheduled run cuts the next `v24.04-YYYYMMDD.N` tag and publishes it without
build cache, so the baked stable toolchain follows upstream stable. GitHub
disables scheduled workflows in a public repository after 60 days without
activity; re-enable it in the Actions tab if that happens. Stable is the one
download not pinned by version: tracking it is the point of the weekly
release. `24.04` and `latest` are moving aliases for the newest published
Ubuntu 24.04 release. Deployments should pin the multi-platform
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
