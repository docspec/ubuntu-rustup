# syntax=docker/dockerfile:1

FROM docker:29.7.2-cli@sha256:000bb62ff495f986c9f5578eb67cc2cb98b91138eda81d7762d5371eb8a497fe AS docker-cli

FROM ghcr.io/actions/actions-runner:2.336.0@sha256:0cfdcc701ce933c6d243c6b0b2da767366dc9f2e99961d4c3754b0b78084cdda AS runtime

ARG TARGETARCH
ARG COMPOSE_VERSION=5.5.0
ARG RUSTUP_VERSION=1.29.0
ARG VERSION=development
ARG REVISION=unknown

LABEL org.opencontainers.image.source="https://github.com/docspec/ubuntu-rustup" \
      org.opencontainers.image.description="Ubuntu 24.04 GitHub Actions runner with Rustup and Docker tooling" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}"

USER root

ENV CARGO_HOME=/home/runner/.cargo \
    RUSTUP_HOME=/home/runner/.rustup \
    PATH=/home/runner/.cargo/bin:${PATH}

# Rust crates commonly require a native linker and pkg-config at build time.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        git-lfs \
        pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && install --directory --owner=runner --group=docker \
        /home/runner/.cargo \
        /home/runner/.rustup \
    && rm -f \
        /usr/bin/containerd \
        /usr/bin/containerd-shim-runc-v2 \
        /usr/bin/ctr \
        /usr/bin/docker \
        /usr/bin/docker-init \
        /usr/bin/docker-proxy \
        /usr/bin/dockerd \
        /usr/bin/runc \
    && case "$TARGETARCH" in \
        amd64) rustup_target=x86_64-unknown-linux-gnu; rustup_sha256=4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10 ;; \
        arm64) rustup_target=aarch64-unknown-linux-gnu; rustup_sha256=9732d6c5e2a098d3521fca8145d826ae0aaa067ef2385ead08e6feac88fa5792 ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
       esac \
    && curl --fail --location --show-error \
        --output /tmp/rustup-init \
        "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${rustup_target}/rustup-init" \
    && echo "${rustup_sha256}  /tmp/rustup-init" | sha256sum --check --strict \
    && chmod 0755 /tmp/rustup-init \
    && runuser --user runner -- \
        /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain none \
    && rm /tmp/rustup-init \
    && case "$TARGETARCH" in \
        amd64) compose_arch=x86_64; compose_sha256=c57ab918abd5b05ca7e7d0f275875dd1330a695074f309dc9eab1b49efafcd4b ;; \
        arm64) compose_arch=aarch64; compose_sha256=ff42489f5a9b879d5d117c5ffea6defc27390b3286da8ad52cbc9c6ab5df590e ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
       esac \
    && curl --fail --location --show-error \
        --output /tmp/docker-compose \
        "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${compose_arch}" \
    && echo "${compose_sha256}  /tmp/docker-compose" | sha256sum --check --strict \
    && install --mode=0755 /tmp/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose \
    && rm /tmp/docker-compose

COPY --from=docker-cli \
    /usr/local/bin/docker \
    /usr/local/bin/docker
COPY --from=docker-cli \
    /usr/local/libexec/docker/cli-plugins/docker-buildx \
    /usr/local/lib/docker/cli-plugins/docker-buildx

USER runner
