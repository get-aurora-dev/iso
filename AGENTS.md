# Aurora ISO Build Copilot Instructions

This document provides essential information for coding agents working with the Aurora ISO build repository to minimize exploration time and avoid common build failures.

## Repository Overview

**Aurora ISO** is a dedicated repository for building bootable Aurora ISOs using Titanoboa and the Anaconda installer with WebUI. This is a specialized build system focused solely on creating installation media.

- **Type**: ISO build system for Aurora (KDE-based immutable OS)
- **Base**: Uses pre-built Aurora container images from ghcr.io/ublue-os/aurora
- **Languages**: Bash scripts, YAML configuration
- **Build System**: Just (command runner), GitHub Actions, Titanoboa (ISO builder)
- **Target**: Bootable installation ISOs for Aurora desktop OS

## Repository Structure

### Root Directory Files

- `Justfile` - Build automation recipes for ISO tasks
- `.pre-commit-config.yaml` - Pre-commit hooks for validation
- `README.md` - Repository documentation
- `AGENTS.md` - This file

### Key Directories

- `.github/workflows/` - GitHub Actions workflows for ISO building
- `iso_files/` - ISO configuration and customization scripts
  - `configure_iso_anaconda-webui.sh` - Main ISO configuration script
  - `scope_installer.png` - Aurora installer icon/branding

### Architecture

- **Build Target**: Bootable live ISOs with Anaconda WebUI installer
- **Image Flavors**: main, nvidia-open
- **Fedora Versions**: 42, 43 supported
- **Stream Tags**: `stable`, `latest`
- **Build Process**: GitHub Actions → Titanoboa → ISO creation
- **Base Images**: Uses `ghcr.io/ublue-os/aurora` as foundation

## Build Instructions

### Prerequisites

**ALWAYS install these tools before attempting any builds:**

```bash
# Install Just command runner (REQUIRED for build commands)
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Install pre-commit for validation
pip install pre-commit
```

### Essential Commands

**Build validation (ALWAYS run before making changes):**
```bash
# 1. Validate syntax and formatting (1-2 minutes)
pre-commit run --all-files

# 2. Check Just syntax (requires Just installation)
just check

# 3. Check ISO configuration script syntax
just test-iso-config

# 4. Fix formatting issues automatically
just fix
```

**Utility commands:**
```bash
# Clean build artifacts
just clean

# List all available recipes
just --list

# Validate image/tag/flavor combinations
just validate aurora stable main

# Clone common repository (for flatpak lists)
just clone-common

# Generate flatpak list from common repo
just generate-flatpak-list

# Get image name for a specific combination
just image_name aurora stable main
# Output: aurora

just image_name aurora stable nvidia-open
# Output: aurora-nvidia-open
```

### Critical Build Notes

1. **ISOs are built in GitHub Actions** - local builds are not supported by default
2. **Always run `just check` before making changes** - catches syntax errors early
3. **Pre-commit hooks are mandatory** - run `pre-commit run --all-files` to validate changes
4. **ISO builds require significant resources** (40GB+ disk, 8GB+ RAM, 60+ minute runtime)
5. **Test the configuration script syntax** with `just test-iso-config`

### Common Build Failures & Workarounds

**Pre-commit failures:**
```bash
# Fix end-of-file and trailing whitespace automatically
pre-commit run --all-files
```

**Just syntax errors:**
```bash
# Auto-fix formatting
just fix

# Manual validation
just check
```

**ISO configuration script errors:**
```bash
# Validate bash syntax
just test-iso-config

# Manual check
bash -n iso_files/configure_iso_anaconda-webui.sh
```

## Validation Pipeline

### Pre-commit Hooks (REQUIRED)

The repository uses mandatory pre-commit validation:

- `check-json` - Validates JSON syntax
- `check-toml` - Validates TOML syntax
- `check-yaml` - Validates YAML syntax
- `end-of-file-fixer` - Ensures files end with newline
- `trailing-whitespace` - Removes trailing whitespace

**Always run:** `pre-commit run --all-files` before committing changes.

### GitHub Actions Workflows

- `reusable-build-iso-anaconda-webui.yml` - Main ISO build workflow
  - Runs on: Pull requests, workflow dispatch, monthly schedule
  - Builds ISOs for main and nvidia-open flavors
  - Uploads to CloudFlare R2 for stable releases
- `validate-just.yml` - Validates Justfile syntax

**Workflow Architecture:**

- ISO builds use Titanoboa action from ublue-os/titanoboa
- Configuration happens in `configure_iso_anaconda-webui.sh`
- Flatpaks are dynamically generated from Brewfiles in get-aurora-dev/common repository
- ISOs are uploaded to CloudFlare R2 for distribution

### Manual Validation Steps

1. `pre-commit run --all-files` - Runs validation hooks (1-2 minutes)
2. `just check` - Validates Just syntax (30 seconds)
3. `just test-iso-config` - Validates ISO configuration script (5 seconds)
4. `just fix` - Auto-fixes formatting issues (30 seconds)

## ISO Configuration

### Main Configuration Script

The ISO is customized via `iso_files/configure_iso_anaconda-webui.sh`:
The ISO includes a custom Anaconda profile at `/etc/anaconda/profile.d/aurora.conf`:

**Key Customizations:**
- Installs Anaconda WebUI installer (anaconda-webui, anaconda-live, firefox)
- Configures Anaconda profile for Aurora
- Sets up BTRFS partitioning scheme with compression
- Adds installer to KDE panel and kickoff menu
- Configures secure boot key enrollment
- Installs flatpaks dynamically generated from Brewfiles
- Disables unnecessary services in live environment

**Making Configuration Changes:**

1. Edit `iso_files/configure_iso_anaconda-webui.sh`
2. Validate syntax: `just test-iso-config`
3. Run pre-commit hooks: `pre-commit run --all-files`
4. Test in PR to trigger ISO build

### Anaconda Configuration

The ISO includes a custom Anaconda profile at `/etc/anaconda/profile.d/aurora.conf`:

- **Profile ID**: aurora
- **OS Detection**: Matches os-release with `os_id = aurora`
- **Network**: First wired connection auto-enabled
- **Bootloader**: Uses Fedora EFI directory, auto-hide menu
- **Storage**: BTRFS with zstd:1 compression, custom partitioning scheme
- **UI**: Custom stylesheet, hides network and password spokes

### Kickstart Configuration

Interactive kickstart includes:
- OSTree container source from ghcr.io/ublue-os/aurora
- Bootc configuration for signed images
- Fedora Flatpak repo disabling
- System flatpak installation
- Secure boot key enrollment (password: `universalblue`)

## Build System Deep Dive

### Justfile Structure

The `Justfile` contains ISO-specific build orchestration:

**Validation Recipes:**
- `just check` - Validates Just syntax across all .just files
- `just fix` - Auto-formats Just files
- `just validate <image> <tag> <flavor>` - Validates image/tag/flavor combinations
- `just test-iso-config` - Validates ISO configuration script syntax

**Utility Recipes:**
- `just clean` - Removes build artifacts and cloned repos
- `just image_name <image> <tag> <flavor>` - Generates image name for specific combo
- `just clone-common` - Clones get-aurora-dev/common repository
- `just generate-flatpak-list` - Generates flatpak list from common repo

**Image/Tag Definitions:**

```bash
images: aurora
flavors: main, nvidia-open
tags: stable, latest
```

### GitHub Actions Workflow

The `reusable-build-iso-anaconda-webui.yml` workflow:

1. **Maximizes build space** - Removes unnecessary software
2. **Validates Just syntax** - Ensures build recipes are valid
3. **Formats image reference** - Constructs proper image reference
4. **Generates flatpak list** - Dynamically from Brewfiles in common repo
5. **Builds ISO with Titanoboa** - Uses ublue-os/titanoboa@main action
6. **Renames and checksums ISO** - Prepares for distribution
7. **Uploads artifacts** - To GitHub Actions (PRs) or CloudFlare R2 (stable)

**Build Arguments:**
- `image-ref` - Full container image reference
- `flatpaks-list` - Path to dynamically generated flatpak list file
- `hook-post-rootfs` - Path to ISO configuration script
- `kargs` - Kernel arguments (currently NONE)

## Development Guidelines

### Making Changes

1. **ALWAYS validate first:** `just check && pre-commit run --all-files`
2. **Make minimal modifications** - prefer configuration over code changes
3. **Test formatting:** `just fix` to auto-format
4. **Test ISO config syntax:** `just test-iso-config`
5. **Test in PRs** - ISO builds run automatically on PR creation

### File Editing Best Practices

- **JSON files**: Validate syntax with `pre-commit run check-json`
- **YAML files**: Validate syntax with `pre-commit run check-yaml`
- **Justfile**: Always run `just check` after modifications
- **Shell scripts**: Follow existing patterns in iso_files/, validate with `bash -n`

### Common Modification Patterns

- **ISO branding**: Update files in `iso_files/` (images, scripts)
- **Anaconda configuration**: Edit profile in `configure_iso_anaconda-webui.sh`
- **Flatpak lists**: Modify Brewfiles in get-aurora-dev/common repository
- **Build workflow**: Edit `.github/workflows/reusable-build-iso-anaconda-webui.yml`
- **Partitioning scheme**: Update `default_partitioning` in Anaconda profile
- **Live environment**: Add/remove packages in `configure_iso_anaconda-webui.sh`

## Trust These Instructions

**The information in this document has been validated against the current repository state.** Only search for additional information if:
- Instructions are incomplete for your specific task
- You encounter errors not covered in the workarounds section
- Repository structure has changed significantly

This repository is focused and straightforward. Following these instructions will significantly reduce build failures and exploration time.

## Other Rules that are Important to the Maintainers

- Ensure that [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) are used and enforced for every commit and pull request title.
- Always be surgical with the least amount of code, the project strives to be easy to maintain.
- Documentation for Aurora exists at https://docs.getaurora.dev/

## Attribution Requirements

AI agents must disclose what tool and model they are using in the "Assisted-by" commit footer:

```text
Assisted-by: [Model Name] via [Tool Name]
```

Example:

```text
Assisted-by: Claude 3.5 Sonnet via Zed AI
```

## Key Differences from Aurora Main Repository

This repository is **ISO-only** and differs from the main Aurora repository:

1. **No container building** - Uses pre-built Aurora images from GHCR
2. **No image variants** - Only builds ISOs, not the OS itself
3. **Simplified Justfile** - Only ISO-related recipes
4. **Single workflow focus** - ISO building only
5. **External dependencies** - Dynamically generates flatpak lists from Brewfiles in get-aurora-dev/common

## Quick Reference

### Validation Commands
```bash
pre-commit run --all-files  # Full validation
just check                   # Just syntax
just test-iso-config         # ISO script syntax
just fix                     # Auto-fix formatting
```

### Utility Commands
```bash
just clean                   # Clean artifacts
just clone-common            # Clone common repo
just generate-flatpak-list   # Generate flatpak list
just image_name aurora stable main  # Get image name
```

### Valid Combinations
```bash
# Images: aurora
# Flavors: main, nvidia-open
# Tags: stable, latest

just validate aurora stable main
just validate aurora stable nvidia-open
just validate aurora latest main
just validate aurora latest nvidia-open
```
