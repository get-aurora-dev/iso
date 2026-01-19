# Aurora ISO Build Copilot Instructions

This document provides essential information for coding agents working with the Aurora ISO build repository to minimize exploration time and avoid common build failures.

## Repository Overview

**Aurora ISO** is a dedicated repository for building bootable Aurora ISOs using Titanoboa and the Anaconda installer with WebUI. This is a specialized build system focused solely on creating installation media.

- **Type**: ISO build system for Aurora (KDE-based immutable OS)
- **Base**: Uses pre-built Aurora container images from `ghcr.io/ublue-os/aurora`
- **Languages**: Bash scripts, YAML configuration
- **Build System**: Just (command runner), GitHub Actions, Titanoboa (ISO builder)
- **Target**: Bootable installation ISOs with Anaconda WebUI installer for Aurora desktop OS

## Repository Structure

### Root Directory Files

- `Justfile` - Build automation recipes for ISO tasks
- `.pre-commit-config.yaml` - Pre-commit hooks for validation
- `README.md` - Repository documentation
- `AGENTS.md` - This file
- `LICENSE` - Apache 2.0 license

### Key Directories

- `.github/workflows/` - GitHub Actions workflows for ISO building
  - `build-iso-stable.yml` - Caller workflow for stable variant
  - `reusable-build-iso-anaconda.yml` - Main ISO build workflow with matrix strategy
  - `validate-just.yml` - Validates Justfile syntax
- `iso_files/` - ISO configuration and customization scripts
  - `configure_iso_anaconda.sh` - Main ISO configuration script
  - `scope_installer.png` - Aurora installer icon/branding

### Architecture

- **Build Target**: Bootable live ISOs with Anaconda WebUI installer
- **Image Flavors**: `main`, `nvidia-open`
- **ISO Variants**: `stable`, `latest`
- **Platforms**: `amd64` (x86_64) only
- **Fedora Versions**: 42+ (WebUI requires F42+)
- **Build Process**: GitHub Actions → Titanoboa → ISO creation with WebUI
- **Base Images**: Uses `ghcr.io/ublue-os/aurora*` as foundation

## Build Instructions

### Prerequisites

**ALWAYS install these tools before attempting any builds:**

```bash
# Install Just command runner (REQUIRED for build commands)
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Verify container runtime (for local builds)
podman --version || docker --version

# Install pre-commit for validation
pip install pre-commit
```

**Note**: Local ISO builds are extremely resource-intensive. Most development work should be tested via GitHub Actions workflows.

### Essential Commands

**Validation (ALWAYS run before committing changes):**
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

# Generate flatpak list from common repo Brewfiles
just generate-flatpak-list

# Get image name for a specific combination
just image_name aurora stable main
# Output: aurora

just image_name aurora stable nvidia-open
# Output: aurora-nvidia-open
```

### Critical Build Notes

1. **ISOs are built in GitHub Actions** - local builds are not recommended
   - Requires 40GB+ free disk space
   - Takes 30-60 minutes per ISO
   - Requires privileged container access
2. **Always run `just check` before making changes** - catches syntax errors early
3. **Pre-commit hooks are mandatory** - run `pre-commit run --all-files` to validate changes
4. **ISO builds require significant resources** (40GB+ disk, 8GB+ RAM, 60+ minute runtime)
5. **Test the configuration script syntax** with `just test-iso-config`
6. **Test via workflow dispatch** rather than local builds when possible

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
bash -n iso_files/configure_iso_anaconda.sh
```

**ISO build failures:**
- Ensure adequate disk space (40GB+ free)
- Clean previous builds: `just clean`
- Check container runtime: `podman system info`
- Verify base image exists and is pullable
- Check hook scripts for syntax errors

## Validation Pipeline

### Pre-commit Hooks (REQUIRED)

The repository uses mandatory pre-commit validation:

- `check-json` - Validates JSON syntax
- `check-toml` - Validates TOML syntax
- `check-yaml` - Validates YAML syntax (includes workflow files)
- `end-of-file-fixer` - Ensures files end with newline
- `trailing-whitespace` - Removes trailing whitespace

**Always run:** `pre-commit run --all-files` before committing changes.

### GitHub Actions Workflows

- `build-iso-stable.yml` - Builds stable ISO images (calls reusable workflow)
  - Triggers on: PR (when ISO files change), weekly schedule (Tuesdays), workflow dispatch
- `reusable-build-iso-anaconda.yml` - Core ISO build logic with matrix strategy
  - Builds multiple flavor combinations in parallel
  - Uses Titanoboa for ISO generation
  - Uploads to CloudFlare R2 test bucket (scheduled/manual) or GitHub artifacts (configurable)
- `validate-just.yml` - Validates Justfile syntax

**Workflow Architecture:**

- Caller workflow (stable) calls reusable workflow with input-controlled uploads
- Reusable workflow uses matrix strategy for parallel builds
- Supports workflow dispatch for manual builds with configurable upload destinations
- Automatically builds on ISO configuration changes (PR validation only, no uploads)
- ISO builds use Titanoboa action from `ublue-os/titanoboa`
- Configuration happens in `configure_iso_anaconda.sh`
- Flatpaks are dynamically generated from Brewfiles in `get-aurora-dev/common` repository
- ISOs are uploaded to CloudFlare R2 test bucket (scheduled builds) or GitHub artifacts (optional)
- PR builds validate configuration but do not upload ISOs

### Manual Validation Steps

1. `pre-commit run --all-files` - Runs validation hooks (1-2 minutes)
2. `just check` - Validates Just syntax (30 seconds)
3. `just test-iso-config` - Validates ISO configuration script (5 seconds)
4. `just fix` - Auto-fixes formatting issues (30 seconds)
5. Test via workflow dispatch rather than local builds when possible

## ISO Configuration

### Main Configuration Script

The ISO is customized via `iso_files/configure_iso_anaconda.sh`:

**Key Customizations:**
- Installs Anaconda WebUI installer (anaconda-webui, anaconda-live, firefox)
- Configures Anaconda profile for Aurora (`/etc/anaconda/profile.d/aurora.conf`)
- Sets up BTRFS partitioning scheme with zstd:1 compression
- Adds installer to KDE panel and kickoff menu
- Configures secure boot key enrollment (password: `universalblue`)
- Installs flatpaks dynamically generated from Brewfiles
- Disables unnecessary services in live environment
- Configures KDE desktop environment for installer

**Making Configuration Changes:**

1. Edit `iso_files/configure_iso_anaconda.sh`
2. Validate syntax: `just test-iso-config`
3. Run pre-commit hooks: `pre-commit run --all-files`
4. Test in PR to trigger ISO build via GitHub Actions

### Anaconda Configuration

The ISO includes a custom Anaconda profile at `/etc/anaconda/profile.d/aurora.conf`:

- **Profile ID**: aurora
- **OS Detection**: Matches os-release with `os_id = aurora`
- **Network**: First wired connection auto-enabled
- **Bootloader**: Uses Fedora EFI directory, auto-hide menu
- **Storage**: BTRFS with zstd:1 compression, custom partitioning scheme
- **UI**: Custom stylesheet, hides network and password spokes
- **WebUI**: Uses Anaconda WebUI for modern installer experience (F42+)

### Kickstart Configuration

Interactive kickstart includes:
- OSTree container source from `ghcr.io/ublue-os/aurora`
- Bootc configuration for signed images
- Fedora Flatpak repo disabling
- System flatpak installation
- Secure boot key enrollment (password: `universalblue`)

### Flatpak Management

Flatpaks are pre-installed on the ISO for offline installation:

**Dynamic Generation:**
- Flatpak lists are dynamically generated from Brewfiles in `get-aurora-dev/common` repository
- The workflow clones the common repo and extracts flatpak IDs from `*system-flatpaks.Brewfile` files
- Generated list is passed to Titanoboa during ISO build

**Adding Flatpaks:**
1. Edit Brewfile in `get-aurora-dev/common` repository (not this repo)
2. Add flatpak entries in Brewfile format: `flatpak "app.id"`
3. Flatpaks are automatically included in next ISO build
4. Ensure flatpaks exist on Flathub before adding

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
- `just generate-flatpak-list` - Generates flatpak list from common repo Brewfiles
- `just verify-container <container> <registry> <key>` - Verifies container signatures with cosign

**Image/Tag Definitions:**

```bash
images: aurora
flavors: main, nvidia-open
tags: stable, latest
```

### GitHub Actions Workflow

The `reusable-build-iso-anaconda.yml` workflow:

1. **Maximizes build space** - Removes unnecessary software (amd64 only)
2. **Validates Just syntax** - Ensures build recipes are valid
3. **Formats image reference** - Constructs proper image reference
4. **Generates flatpak list** - Dynamically from Brewfiles in common repo
5. **Builds ISO with Titanoboa** - Uses `ublue-os/titanoboa@main` action
6. **Renames and checksums ISO** - Prepares for distribution
7. **Uploads artifacts** - To GitHub Actions (PRs) or CloudFlare R2 (stable)

**Build Arguments:**
- `image-ref` - Full container image reference (e.g., `ghcr.io/ublue-os/aurora:stable`)
- `flatpaks-list` - Path to dynamically generated flatpak list file
- `hook-post-rootfs` - Path to ISO configuration script (`configure_iso_anaconda.sh`)
- `kargs` - Kernel arguments (currently NONE)

**Build Matrix:**
- **Platform**: amd64 (x86_64) only
- **Flavors**: main, nvidia-open
- **Variants**: stable (latest can be added as needed)
- Parallel builds for each flavor combination

## Workflow Deep Dive

### Reusable ISO Build Workflow

The `reusable-build-iso-anaconda.yml` is the core workflow:

**Trigger conditions:**
- Workflow dispatch (manual builds)
- Pull requests - on ISO configuration changes
- Schedule - Monthly builds on 1st at 2:00 AM UTC
- Workflow call - from other workflows (e.g., stable)

**Build matrix:**
Dynamically generates matrix based on configuration:
- **Platform**: amd64 (x86_64) - uses `ubuntu-24.04` runner
- **Flavors**: main, nvidia-open
- **Variants**: stable (primary), latest (when needed)

**Build process:**
1. Setup build environment (maximize disk space for amd64)
2. Checkout repository and setup Just
3. Validate Just syntax with `just check`
4. Format image reference and determine kernel args
5. Clone common repo and generate flatpak list from Brewfiles
6. Build ISO using Titanoboa action with WebUI configuration
7. Rename ISO and generate checksum
8. Upload to CloudFlare R2 (stable, non-PR) or GitHub artifacts (PRs)

**Key workflow features:**
- Parallel builds across matrix
- Conditional uploads based on event type and variant
- Dynamic flatpak list generation from external Brewfile repository
- WebUI-specific Anaconda configuration
- Separate artifact naming for each flavor/variant combination

### Stable Workflow

The `build-iso-stable.yml` is a caller workflow:
- Triggers on PR (ISO file changes), weekly schedule (Tuesdays at 03:15 UTC), or workflow dispatch
- Calls reusable workflow with input-controlled upload parameters
- Builds both main and nvidia-open flavors for stable variant
- Uses `secrets: inherit` to pass CloudFlare R2 credentials
- Passes upload_artifacts and upload_r2 inputs to control upload destinations

### Standard Caller Workflow Pattern

**All caller workflows MUST follow this pattern without deviation.**

Caller workflows follow a **strict, consistent structure** to ensure maintainability:

```yaml
---
name: Build Stable ISOs
on:
  pull_request:
    branches:
      - main
    paths:
      - ".github/workflows/build-iso-stable.yml"
      - ".github/workflows/reusable-build-iso-anaconda.yml"
      - "iso_files/**"
  schedule:
    - cron: "15 3 * * 2"  # 3:15am UTC on Tuesdays
  workflow_call:
  workflow_dispatch:

jobs:
  build-iso-stable:
    name: Build Stable ISOs
    uses: ./.github/workflows/reusable-build-iso-anaconda.yml
    secrets: inherit
    with:
      upload_artifacts: ${{ github.event_name == 'workflow_dispatch' && inputs.upload_artifacts || false }}
      upload_r2: ${{ github.event_name == 'workflow_dispatch' && inputs.upload_r2 || true }}
```

**Key Pattern Rules:**

1. **NO permissions block in caller**: The reusable workflow handles all permissions internally
2. **Use `secrets: inherit`**: Required for CloudFlare R2 upload credentials
3. **Consistent triggers**: PR, schedule, workflow_dispatch (workflow_call optional if needed by other workflows)
4. **Single job pattern**: Each caller has exactly one job calling the reusable workflow
5. **Path filters**: Only trigger on relevant file changes
6. **Input passing**: Use `with:` block to pass inputs to reusable workflow for upload control

## Configuration Files

### Key Configuration Locations

- `iso_files/` - ISO configuration and hook scripts
- `.github/workflows/` - CI/CD pipeline definitions
- `Justfile` - Main build recipes
- `.pre-commit-config.yaml` - Pre-commit hook configuration
- `.gitignore` - Git ignore patterns for build artifacts

### Linting/Build Configurations

- `.pre-commit-config.yaml` - Pre-commit hook configuration
- `Justfile` - ISO build recipe definitions
- `.gitignore` - Git ignore patterns (output/, common/, *.iso*, flatpaks.list)

## Development Guidelines

### Making Changes

1. **ALWAYS validate first:** `just check && pre-commit run --all-files`
2. **Make minimal modifications** - prefer configuration over code changes
3. **Test formatting:** `just fix` to auto-format
4. **Test ISO config syntax:** `just test-iso-config`
5. **Test in PRs** - ISO builds run automatically on PR creation for ISO file changes
6. **Use workflow dispatch** for manual testing without PR

### File Editing Best Practices

- **JSON files**: Validate syntax with `pre-commit run check-json`
- **YAML files**: Validate syntax with `pre-commit run check-yaml`
- **Justfile**: Always run `just check` after modifications
- **Shell scripts**: Follow existing patterns in `iso_files/`, validate with `bash -n`
- **Workflow files**: Test in fork first before opening PR

### Common Modification Patterns

- **ISO branding**: Update files in `iso_files/` (images, scripts)
- **Anaconda configuration**: Edit profile in `configure_iso_anaconda.sh`
- **Flatpak lists**: Modify Brewfiles in `get-aurora-dev/common` repository (not this repo)
- **Build workflow**: Edit `.github/workflows/reusable-build-iso-anaconda.yml`
- **Partitioning scheme**: Update `default_partitioning` in Anaconda profile
- **Live environment**: Add/remove packages in `configure_iso_anaconda.sh`
- **WebUI configuration**: Modify Anaconda WebUI settings in configuration script

### Testing ISO Changes

1. **Configuration script changes**: Validate with `just test-iso-config` first
2. **Workflow changes**: Test via workflow dispatch in your fork
3. **Flatpak changes**: Edit Brewfiles in common repo, trigger new ISO build
4. **PR testing**: ISOs build automatically for PRs with ISO file changes
5. **Manual testing**: Use workflow dispatch for on-demand builds

## Trust These Instructions

**The information in this document has been validated against the current repository state.** Only search for additional information if:
- Instructions are incomplete for your specific task
- You encounter errors not covered in the workarounds section
- Repository structure has changed significantly

This repository is focused and straightforward. Following these instructions will significantly reduce build failures and exploration time.

## Best Practices for AI Agents

### DO:
- ✅ Make minimal, surgical changes
- ✅ Focus on ISO configuration and workflows
- ✅ Use conventional commits
- ✅ Run validation before committing
- ✅ Test via workflow dispatch when possible
- ✅ Use existing patterns and conventions
- ✅ Include AI attribution in commits

### DON'T:
- ❌ Modify base image building (wrong repo)
- ❌ Remove or edit working code unnecessarily
- ❌ Skip validation steps
- ❌ Build ISOs locally unless necessary
- ❌ Use non-conventional commit messages
- ❌ Add flatpaks directly to this repo (use common repo Brewfiles)
- ❌ Change workflow patterns without understanding the architecture

### Common Pitfalls:
- **Large builds:** ISOs are resource-intensive (40GB+ disk, 60+ min), prefer GitHub Actions
- **Pre-commit failures:** Always run `pre-commit run --all-files` before commit
- **Just syntax errors:** Run `just check` and `just fix`
- **Workflow testing:** Test in fork first with workflow dispatch
- **Flatpak management:** Flatpaks come from common repo Brewfiles, not managed here
- **WebUI requirements:** Anaconda WebUI requires Fedora 42+

## Commit Conventions (MANDATORY)

This repository uses [Conventional Commits](https://www.conventionalcommits.org/):

**Format:** `<type>(<scope>): <description>`

**Types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `ci:` - CI/CD changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

**Scopes:**
- `iso` - ISO configuration and build
- `workflow` - GitHub Actions workflows
- `config` - Configuration files
- `flatpak` - Flatpak management

**Examples:**
- `feat(iso): add support for latest tag`
- `fix(config): correct Anaconda profile syntax`
- `docs(readme): update build instructions`
- `ci(workflow): optimize matrix strategy`

**AI Attribution (REQUIRED):**
AI agents must disclose what tool and model they are using in the "Assisted-by" commit footer:

```text
Assisted-by: [Model Name] via [Tool Name]
```

Example:

```text
feat(iso): add KDE plasma widget to installer

Add custom KDE widget to installer panel

Assisted-by: Claude 3.5 Sonnet via Zed AI
```

## Key Differences from Aurora Main Repository

This repository is **ISO-only** and differs from the main Aurora repository:

1. **No container building** - Uses pre-built Aurora images from GHCR
2. **No image variants** - Only builds ISOs, not the OS itself
3. **Simplified Justfile** - Only ISO-related recipes
4. **Single workflow focus** - ISO building only with WebUI
5. **External dependencies** - Dynamically generates flatpak lists from Brewfiles in `get-aurora-dev/common`
6. **WebUI-specific** - Uses Anaconda WebUI installer (requires F42+)
7. **KDE-focused** - Configuration optimized for KDE Plasma desktop

## Other Rules Important to Maintainers

- Ensure that [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) are used and enforced for every commit and pull request title
- Always be surgical with the least amount of code, the project strives to be easy to maintain
- Documentation for Aurora exists at https://docs.getaurora.dev/
- Main Aurora repository: https://github.com/ublue-os/aurora
- Common configuration repository: https://github.com/get-aurora-dev/common

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
just clean                          # Clean artifacts
just clone-common                   # Clone common repo
just generate-flatpak-list          # Generate flatpak list
just image_name aurora stable main  # Get image name
just verify-container <container>   # Verify container signature
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

### Build Matrix (Current)
- **Platforms**: amd64 only
- **Flavors**: main, nvidia-open
- **Variants**: stable (primary), latest (when needed)
- **Total ISOs**: 2 (amd64 × main, amd64 × nvidia-open) for stable

## Related Resources

- **Aurora documentation:** https://docs.getaurora.dev/
- **Main Aurora repo:** https://github.com/ublue-os/aurora
- **Common config repo:** https://github.com/get-aurora-dev/common
- **Titanoboa ISO builder:** https://github.com/ublue-os/titanoboa
- **Universal Blue:** https://universal-blue.org/

## Summary

This repository is focused exclusively on ISO generation for Aurora with Anaconda WebUI. It uses pre-built container images and configures them for bootable installation media using Titanoboa. Development should focus on ISO configuration scripts, workflows, and coordination with the common repository for flatpak management. Always validate changes, use conventional commits, and prefer GitHub Actions for testing over local builds due to resource requirements.
