# Aurora ISO Builder

[![Build ISOs](https://github.com/get-aurora-dev/iso/actions/workflows/build-iso-stable.yml/badge.svg)](https://github.com/get-aurora-dev/iso/actions/workflows/build-iso-stable.yml)

## Overview

This repo creates installation media for [Aurora](https://getaurora.dev), these ISOs provide a live environment with the Anaconda WebUI installer and [plasma-setup](https://invent.kde.org/plasma/plasma-setup) which handles user creation and other things which have to be done on first boot. These ISOs are only compatible with UEFI and will not boot on systems with a legacy bios boot implementation.

## Download

Pre-built ISOs are available at [getaurora.dev](https://getaurora.dev).

Testing ISOs are available [here](https://docs.getaurora.dev/guides/iso-testing).

Size usually ranges from 6GB to 8GB depending on the required runtimes by the preinstalled Flatpak applications and of course the container image size itself.

## Verifying ISOs

### 1. Integrity Check (Checksum)

You can verify the SHA256 checksum of your downloaded ISO against the published checksum file:

```bash
sha256sum --check <iso-name>.iso-CHECKSUM
```

Example:

```bash
sha256sum --check aurora-stable-webui-x86_64.iso-CHECKSUM
aurora-stable-webui-x86_64.iso: OK
```

### 2. Provenance Attestation (GitHub Actions)

All official ISOs built via GitHub Actions include signed cryptographic build provenance attestations. You can verify that the ISO was built and published directly by the Aurora team by using the [GitHub CLI (`gh`)](https://cli.github.com/):

```bash
gh attestation verify <iso-name>.iso --owner get-aurora-dev
```

Example:

```
gh attestation verify aurora-stable-webui-x86_64.iso --owner get-aurora-dev
Loaded digest sha256:5738320c906bdbae6fbb87be7bc0e30cc11cc6975916a0e28da9086641513f22 for file://aurora-stable-webui-x86_64.iso
Loaded 1 attestation from GitHub API

The following policy criteria will be enforced:
- Predicate type must match:................ https://slsa.dev/provenance/v1
- Source Repository Owner URI must match:... https://github.com/get-aurora-dev
- Subject Alternative Name must match regex: (?i)^https://github\.com/get-aurora-dev/
- OIDC Issuer must match:................... https://token.actions.githubusercontent.com

✓ Verification succeeded!

The following 1 attestation matched the policy criteria

- Attestation #1
- Build repo:..... get-aurora-dev/iso
- Build workflow:. .github/workflows/build-iso-stable.yml@refs/heads/gh-readonly-queue/main/pr-85-3c092658d6fa47a1702442a7fc1c614a38ede582
- Signer repo:.... get-aurora-dev/iso
- Signer workflow: .github/workflows/reusable-build-iso-anaconda.yml@refs/heads/gh-readonly-queue/main/pr-85-3c092658d6fa47a1702442a7fc1c614a38ede582
```

### Flavors

- **main**: Standard Aurora ISO with open-source drivers
- **nvidia-open**: Aurora ISO with NVIDIA Open kernel modules

There will be no ISOs for [DX images](https://docs.getaurora.dev/dx/aurora-dx-intro).

### Versions

- **stable**: Built on top of aurora:stable images
- **testing**: Built on top of aurora:testing images

See the [release stream docs](https://docs.getaurora.dev/guides/release-streams).

There will be no ISOs for `:latest` images.

## Secure Boot

Secure boot is supported by default. After installation, users are prompted to enroll the secure boot key with password: `universalblue`

## Build Overview

1. Generate flatpak list dynamically via Brewfiles from [common repo](https://github.com/get-aurora-dev/common)
2. Build Container Image which is a regular aurora image tailored for the live environment
3. Generate ISO with Titanoboa which embeds a regular aurora image into the live environments container storage
4. Generate checksums and build provenance attestations
5. Upload to CloudFlare R2 test bucket (scheduled builds) or GitHub artifacts for PRs

### ISO Promotion Workflow

The promotion workflow (`promote-iso.yml`) copies ISOs from the test bucket to production.

#### Usage

To promote ISOs to production:

1. Go to Actions → Promote ISOs to Production
2. Click "Run workflow"
3. First run with **dry_run = true** to preview changes
4. Review the dry-run output
5. Run again with **dry_run = false** to execute promotion

**Note**: The promotion workflow uses `rclone sync`, which will:
- Copy new files from test to production
- Update existing files if changed
- Remove ISO and CHECKSUM files from production that don't exist in test (subject to the rclone include filters)

## Documentation

- [Aurora Documentation](https://docs.getaurora.dev/)
- [Universal Blue Docs](https://universal-blue.org/)
- [Titanoboa](https://github.com/ublue-os/titanoboa) - ISO builder tool

## Resources

- [Aurora Website](https://getaurora.dev)
- [Aurora Repository](https://github.com/ublue-os/aurora)
- [Universal Blue](https://universal-blue.org)
- [Discussions](https://github.com/ublue-os/aurora/discussions)

## Acknowledgments

- [Titanoboa](https://github.com/ublue-os/titanoboa) for ISO creation
- [Anaconda WebUI](https://github.com/rhinstaller/anaconda-webui) for the installer
- [Slitherer](https://gitlab.com/VelocityLimitless/Projects/slitherer) for providing the runner used by Anaconda
