FROM mcr.microsoft.com/devcontainers/base:ubuntu

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-transport-https \
       ca-certificates \
       curl \
       gnupg \
       lsb-release \
       software-properties-common \
       unzip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
    && TERRAFORM_VERSION="1.9.8" \
    && EXPECTED_HASHICORP_FPR="798AEC654E5C15428C8E42EEAA16FCBCA621E701" \
    && ARCH="$(dpkg --print-architecture)" \
    && if [ "${ARCH}" = "amd64" ]; then TF_ARCH="amd64"; \
       elif [ "${ARCH}" = "arm64" ]; then TF_ARCH="arm64"; \
       else echo "Unsupported architecture: ${ARCH}" && exit 1; fi \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor >/tmp/hashicorp-keyring.gpg \
    && ACTUAL_HASHICORP_FPR="$(gpg --show-keys --with-colons /tmp/hashicorp-keyring.gpg | awk -F: '/^fpr:/ {print $10; exit}')" \
    && [ "${ACTUAL_HASHICORP_FPR}" = "${EXPECTED_HASHICORP_FPR}" ] \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" -o /tmp/terraform.zip \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" -o /tmp/terraform_SHA256SUMS \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" -o /tmp/terraform_SHA256SUMS.sig \
    && gpg --batch --no-default-keyring --keyring /tmp/hashicorp-keyring.gpg --verify /tmp/terraform_SHA256SUMS.sig /tmp/terraform_SHA256SUMS \
    && grep "terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" /tmp/terraform_SHA256SUMS | sha256sum -c - \
    && unzip -q /tmp/terraform.zip -d /usr/local/bin \
    && rm -f /tmp/terraform.zip /tmp/terraform_SHA256SUMS /tmp/terraform_SHA256SUMS.sig /tmp/hashicorp-keyring.gpg

RUN set -eux \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/usr/share/keyrings/microsoft-archive-keyring.gpg \
    && ARCH="$(dpkg --print-architecture)" \
    && AZ_REPO="$(lsb_release -cs)" \
    && echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ ${AZ_REPO} main" >/etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends azure-cli \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
    && ARCH="$(dpkg --print-architecture)" \
    && if [ "${ARCH}" = "amd64" ]; then AWS_ARCH="x86_64"; \
       elif [ "${ARCH}" = "arm64" ]; then AWS_ARCH="aarch64"; \
       else echo "Unsupported architecture: ${ARCH}" && exit 1; fi \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "/tmp/awscliv2.zip" \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

RUN set -eux \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor >/usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" >/etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*
