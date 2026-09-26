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
    && ARCH="$(dpkg --print-architecture)" \
    && if [ "${ARCH}" = "amd64" ]; then TF_ARCH="amd64"; EXPECTED_TERRAFORM_SHA256="186e0145f5e5f2eb97cbd785bc78f21bae4ef15119349f6ad4fa535b83b10df8"; \
       elif [ "${ARCH}" = "arm64" ]; then TF_ARCH="arm64"; EXPECTED_TERRAFORM_SHA256="f85868798834558239f6148834884008f2722548f84034c9b0f62934b2d73ebb"; \
       else echo "Unsupported architecture: ${ARCH}" && exit 1; fi \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" -o /tmp/terraform.zip \
    && echo "${EXPECTED_TERRAFORM_SHA256}  /tmp/terraform.zip" | sha256sum -c - \
    && unzip -q /tmp/terraform.zip -d /usr/local/bin \
    && rm -f /tmp/terraform.zip

RUN set -eux \
    && EXPECTED_MICROSOFT_FPR="BC528686B50D79E339D3721CEB3E94ADBE1229CF" \
    && AZ_REPO="$(lsb_release -cs)" \
    && if [ "${AZ_REPO}" != "jammy" ] && [ "${AZ_REPO}" != "noble" ]; then AZ_REPO="jammy"; fi \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/usr/share/keyrings/microsoft-archive-keyring.gpg \
    && read -r MICROSOFT_PRIMARY_KEY_COUNT MICROSOFT_PRIMARY_FPR < <(gpg --show-keys --with-colons /usr/share/keyrings/microsoft-archive-keyring.gpg | awk -F: '$1 == "pub" {want_fpr = 1; next} want_fpr && $1 == "fpr" {count++; if (count == 1) {first = $10}; want_fpr = 0} END {print count + 0, first}') \
    && [ "${MICROSOFT_PRIMARY_KEY_COUNT}" -eq 1 ] \
    && [ "${MICROSOFT_PRIMARY_FPR}" = "${EXPECTED_MICROSOFT_FPR}" ] \
    && ARCH="$(dpkg --print-architecture)" \
    && echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ ${AZ_REPO} main" >/etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends azure-cli \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends awscli \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
    && EXPECTED_GCLOUD_FPR="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor >/usr/share/keyrings/cloud.google.gpg \
    && read -r GCLOUD_PRIMARY_KEY_COUNT GCLOUD_PRIMARY_FPR < <(gpg --show-keys --with-colons /usr/share/keyrings/cloud.google.gpg | awk -F: '$1 == "pub" {want_fpr = 1; next} want_fpr && $1 == "fpr" {count++; if (count == 1) {first = $10}; want_fpr = 0} END {print count + 0, first}') \
    && [ "${GCLOUD_PRIMARY_KEY_COUNT}" -eq 1 ] \
    && [ "${GCLOUD_PRIMARY_FPR}" = "${EXPECTED_GCLOUD_FPR}" ] \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" >/etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*
