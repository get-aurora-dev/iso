# Aurora ISO Builder

[![Build ISOs](https://github.com/ublue-os/aurora-iso/actions/workflows/reusable-build-iso-anaconda-webui.yml/badge.svg)](https://github.com/ublue-os/aurora-iso/actions/workflows/reusable-build-iso-anaconda-webui.yml)

This repository is dedicated to building bootable Aurora ISOs using [Titanoboa](https://github.com/ublue-os/titanoboa) and the Anaconda installer with WebUI.

## Overview

Aurora ISO Builder creates installation media for [Aurora](https://getaurora.dev), a delightful KDE desktop experience built on Universal Blue. These ISOs provide a live environment with the Anaconda WebUI installer for easy installation of Aurora.

### Features

- **Live Environment**: Boots into a fully functional Aurora desktop
- **Anaconda WebUI Installer**: Modern web-based installation experience
- **Multiple Flavors**: Support for standard and NVIDIA Open variants
- **Pre-configured**: Optimized BTRFS partitioning, secure boot support, flatpak integration
- **Monthly Builds**: Automatically built ISOs on the first of each month
- **CloudFlare Distribution**: Stable ISOs automatically uploaded for public access

## Download

Pre-built ISOs are available at [getaurora.dev](https://getaurora.dev).

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── reusable-build-iso-anaconda-webui.yml  # Main ISO build workflow
│       └── validate-just.yml                       # Justfile validation
├── iso_files/
│   ├── configure_iso_anaconda-webui.sh            # ISO configuration script
│   └── scope_installer.png                         # Installer branding
├── .pre-commit-config.yaml                         # Pre-commit hooks
├── AGENTS.md                                       # AI agent documentation
├── Justfile                                        # Build automation recipes
└── README.md                                       # This file
```

## Building ISOs

### Prerequisites

ISOs are built using GitHub Actions, but you can validate your changes locally:

```bash
# Install Just command runner
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Install pre-commit
pip install pre-commit
pre-commit install
```

### Validation

Before submitting changes, validate your code:

```bash
# Check all syntax and formatting
pre-commit run --all-files

# Validate Justfile syntax
just check

# Test ISO configuration script
just test-iso-config

# Auto-fix formatting issues
just fix
```

### Available Just Recipes

```bash
# List all available recipes
just --list

# Clean build artifacts
just clean

# Clone common repository (flatpak lists)
just clone-common

# Generate flatpak list from common repo
just generate-flatpak-list

# Get image name for specific combination
just image_name aurora stable main

# Validate image/tag/flavor combination
just validate aurora stable nvidia-open
```

## ISO Variants

### Flavors

- **main**: Standard Aurora ISO with open-source drivers
- **nvidia-open**: Aurora ISO with NVIDIA Open kernel modules

### Versions

- **stable**: Latest stable Fedora release (recommended)
- **latest**: Current Fedora release

## Configuration

### ISO Customization

The ISO is customized via `iso_files/configure_iso_anaconda-webui.sh`:

- Installs Anaconda WebUI installer
- Configures Aurora-specific Anaconda profile
- Sets up BTRFS partitioning with zstd compression
- Adds installer to KDE panel and kickoff menu
- Configures secure boot key enrollment
- Pre-installs flatpaks (dynamically generated from Brewfiles)

### Anaconda Profile

The custom Aurora profile includes:

- **Storage**: BTRFS with zstd:1 compression
- **Partitioning**: 
  - `/` (1 GiB min, 70 GiB max)
  - `/home` (500 MiB min, 50 GiB free)
  - `/var` (BTRFS)
- **Network**: First wired connection auto-enabled
- **Bootloader**: Fedora EFI directory, auto-hide menu

### Secure Boot

Secure boot is supported by default. After installation, users are prompted to enroll the secure boot key with password: `universalblue`

## GitHub Actions Workflow

### Triggers

- **Pull Requests**: Builds ISOs for testing (uploads to GitHub artifacts)
- **Workflow Dispatch**: Manual triggering
- **Schedule**: First day of each month at 2:00 AM UTC

### Build Matrix

The workflow builds ISOs for:
- Platform: amd64
- Flavors: main, nvidia-open
- Version: stable

### Workflow Steps

1. Maximize build space (removes unnecessary software)
2. Checkout repository
3. Validate Just syntax
4. Format image reference
5. Generate flatpak list dynamically from Brewfiles in common repo
6. Build ISO with Titanoboa
7. Generate checksums
8. Upload to artifacts (PR) or CloudFlare R2 (stable release)

## Contributing

Contributions are welcome! Please follow these guidelines:

### Before Committing

1. Run validation: `just check && pre-commit run --all-files`
2. Test ISO script syntax: `just test-iso-config`
3. Use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#specification)
4. Keep changes minimal and focused

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation locally
5. Submit a pull request
6. Wait for ISO build to complete in GitHub Actions
7. Test the generated ISO if needed

### Common Changes

- **Branding**: Update images in `iso_files/`
- **Anaconda config**: Edit profile in `configure_iso_anaconda-webui.sh`
- **Flatpak lists**: Modify Brewfiles in get-aurora-dev/common repository
- **Partitioning**: Modify `default_partitioning` in Anaconda profile
- **Live environment**: Add/remove packages in configuration script
- **Workflow**: Update `.github/workflows/reusable-build-iso-anaconda-webui.yml`

## Documentation

- [Aurora Documentation](https://docs.getaurora.dev/)
- [Universal Blue Docs](https://universal-blue.org/)
- [AGENTS.md](AGENTS.md) - Comprehensive guide for AI-assisted development
- [Titanoboa](https://github.com/ublue-os/titanoboa) - ISO builder tool

## Resources

- [Aurora Website](https://getaurora.dev)
- [Aurora Repository](https://github.com/ublue-os/aurora)
- [Universal Blue](https://universal-blue.org)
- [Discussions](https://universal-blue.discourse.group/c/aurora/11)

## License

Apache-2.0

## Acknowledgments

- Built on [Universal Blue](https://universal-blue.org) infrastructure
- Uses [Titanoboa](https://github.com/ublue-os/titanoboa) for ISO creation
- Based on [Fedora Kinoite](https://fedoraproject.org/kinoite/)
- Powered by the [ublue-os](https://github.com/ublue-os) community