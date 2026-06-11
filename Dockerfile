FROM debian:bookworm-slim AS builder

ARG OPENTOFU_VERSION=1.12.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /tmp/tofu.zip \
    "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.zip" \
    && unzip /tmp/tofu.zip tofu -d /usr/local/bin/ \
    && rm /tmp/tofu.zip


FROM debian:bookworm-slim

# curl: DO API calls in common.sh; coreutils: shred in common.sh; git: submodules in CI
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/tofu /usr/local/bin/tofu

COPY . /workspace/

WORKDIR /workspace
