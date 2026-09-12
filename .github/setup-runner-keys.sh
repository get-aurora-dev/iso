#!/usr/bin/env bash

# Setup Public Keys for containers that are pulled during the build

set -eoux pipefail

PKI_DIR="/etc/pki/containers"
REGISTRIES="/etc/containers/registries.d"

mkdir -p "${PKI_DIR}" "${REGISTRIES}"
cp ghcr.io-ublue-os.pub "${PKI_DIR}/ghcr.io-ublue-os.pub"

yq -n '.docker."ghcr.io/ublue-os".use-sigstore-attachments = true' | tee "${REGISTRIES}"/ublue-os.yaml

jq '.transports.docker["ghcr.io/ublue-os"] = [
  {
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/ghcr.io-ublue-os.pub",
    "signedIdentity": {
      "type": "matchRepository"
    }
  }
]' /etc/containers/policy.json | tee /etc/containers/policy.json.tmp > /dev/null && mv /etc/containers/policy.json.tmp /etc/containers/policy.json
