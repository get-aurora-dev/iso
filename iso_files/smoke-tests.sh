#!/usr/bin/env bash

set -eoux pipefail

# secureboot key that is enrolled on first-boot, we already have a test for
# kernel on the image build
stat /etc/pki/akmods/certs/akmods-ublue.der
