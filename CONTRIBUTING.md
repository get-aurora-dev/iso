# Contributing to Aurora ISO Builder

Thank you for your interest in contributing to Aurora ISO Builder! This guide will help you get started with contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Style Guide](#style-guide)
- [Resources](#resources)

## Code of Conduct

This project follows the [Universal Blue Code of Conduct](https://universal-blue.org/CODE_OF_CONDUCT/). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following tools installed:

- **Git**: Version control
- **Just**: Command runner for automation
- **Pre-commit**: For running validation hooks
- **Bash**: For running scripts

### Installation

```bash
# Install Just command runner
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Install pre-commit
pip install pre-commit

# Clone the repository
git clone https://github.com/ublue-os/aurora-iso.git
cd aurora-iso

# Install pre-commit hooks
pre-commit install
```

## Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/aurora-iso.git
   cd aurora-iso
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/ublue-os/aurora-iso.git
   ```
4. **Install pre-commit hooks**:
   ```bash
   pre-commit install
   ```

## Making Changes

### Branch Naming

Create a descriptive branch name:
- `feat/add-new-feature` - For new features
- `fix/bug-description` - For bug fixes
- `docs/update-readme` - For documentation changes
- `chore/update-deps` - For maintenance tasks

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `ci`: CI/CD changes

**Examples:**
```
feat: add support for custom kernel arguments

fix: correct Anaconda profile partitioning scheme

docs: update README with new ISO variants

chore: update pre-commit hooks to v5.0.0
```

### Attribution Footer

If using AI assistance, include an attribution footer:

```
feat: improve ISO configuration script

Assisted-by: Claude 3.5 Sonnet via Zed AI
```

## Testing

### Local Validation

Always validate your changes before committing:

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Validate Just syntax
just check

# Test ISO configuration script syntax
just test-iso-config

# Auto-fix formatting issues
just fix
```

### ISO Build Testing

ISO builds are automatically triggered on pull requests. The workflow will:
1. Build ISOs for all configured flavors
2. Generate checksums
3. Upload artifacts to GitHub

You can download and test the generated ISOs from the GitHub Actions artifacts.

### Manual Testing

To manually test the ISO configuration script:

```bash
# Validate bash syntax
bash -n iso_files/configure_iso_anaconda-webui.sh

# Or use the Just recipe
just test-iso-config
```

## Submitting Changes

### Before Submitting

1. **Sync with upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run validation**:
   ```bash
   pre-commit run --all-files
   just check
   just test-iso-config
   ```

3. **Test your changes**: Ensure the ISO builds successfully in GitHub Actions

### Pull Request Process

1. **Push your changes**:
   ```bash
   git push origin your-branch-name
   ```

2. **Create a Pull Request** on GitHub with:
   - Clear title using conventional commit format
   - Detailed description of changes
   - Link to related issues (if applicable)
   - Screenshots or logs (if relevant)

3. **Wait for CI checks** to complete:
   - Just syntax validation
   - Pre-commit hooks
   - ISO build (if workflow files changed)

4. **Address review feedback** if requested

5. **Squash commits** if requested by maintainers

### Pull Request Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Maintenance/chore

## Testing
- [ ] Validated locally with `just check`
- [ ] Ran pre-commit hooks
- [ ] Tested ISO configuration script syntax
- [ ] ISO builds successfully in GitHub Actions

## Related Issues
Closes #123

## Additional Notes
Any additional context or notes for reviewers.
```

## Style Guide

### Shell Scripts

- Use `#!/usr/bin/bash` or `#!/usr/bin/env bash` shebang
- Use `set -eoux pipefail` for strict error handling
- Quote variables: `"${VARIABLE}"`
- Use meaningful variable names in UPPER_CASE
- Add comments for complex logic
- Follow existing patterns in `iso_files/configure_iso_anaconda-webui.sh`

**Example:**
```bash
#!/usr/bin/bash
set -eoux pipefail

readonly IMAGE_NAME="aurora"
readonly IMAGE_VERSION="stable"

if [[ -n "${IMAGE_NAME}" ]]; then
    echo "Building ISO for ${IMAGE_NAME}"
fi
```

### YAML Files

- Use 2 spaces for indentation
- Quote strings when necessary
- Use `---` document separator
- Keep workflows readable with descriptive names

### Justfile

- Use descriptive recipe names
- Add comments for complex recipes
- Group related recipes with `[group('name')]`
- Mark internal recipes with `[private]`
- Use consistent formatting (run `just fix`)

**Example:**
```just
# Build ISO for specific flavor
[group('ISO')]
build-iso flavor="main":
    #!/usr/bin/bash
    set -eoux pipefail
    echo "Building ISO for {{ flavor }}"
```

### Markdown

- Use descriptive headings
- Include code blocks with language specification
- Keep lines under 120 characters when possible
- Use relative links for internal documentation

## Common Tasks

### Adding New ISO Configuration

1. Edit `iso_files/configure_iso_anaconda-webui.sh`
2. Test syntax: `just test-iso-config`
3. Create PR with changes
4. Wait for ISO build to complete
5. Test the generated ISO

### Modifying Flatpak Lists

1. Flatpaks are defined in Brewfiles in the get-aurora-dev/common repository
2. Edit `*system-flatpaks.Brewfile` in the common repository
3. Flatpaks are dynamically extracted during ISO build
4. Format: `flatpak "app.id.here"`

### Updating Workflows

1. Edit workflow file in `.github/workflows/`
2. Validate YAML syntax: `pre-commit run check-yaml`
3. Create PR and monitor workflow execution
4. Ensure all checks pass

### Modifying Justfile

1. Edit `Justfile`
2. Validate syntax: `just check`
3. Test affected recipes
4. Run `just fix` to format
5. Create PR

## Resources

### Documentation
- [Aurora Documentation](https://docs.getaurora.dev/)
- [Universal Blue Docs](https://universal-blue.org/)
- [AGENTS.md](AGENTS.md) - AI agent development guide
- [Titanoboa](https://github.com/ublue-os/titanoboa) - ISO builder

### Community
- [Discourse Forums](https://universal-blue.discourse.group/c/aurora/11)
- [GitHub Discussions](https://github.com/ublue-os/aurora/discussions)
- [Discord](https://discord.gg/universalblue)

### Tools
- [Just Manual](https://just.systems/man/en/)
- [Pre-commit](https://pre-commit.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Getting Help

If you need help:

1. Check the [documentation](https://docs.getaurora.dev/)
2. Review [AGENTS.md](AGENTS.md) for detailed instructions
3. Search existing [issues](https://github.com/ublue-os/aurora-iso/issues)
4. Ask in [Discourse forums](https://universal-blue.discourse.group/c/aurora/11)
5. Join our [Discord](https://discord.gg/universalblue)

## Recognition

Contributors are recognized in several ways:
- Listed in GitHub contributors
- Mentioned in release notes for significant contributions
- Acknowledged in project documentation

Thank you for contributing to Aurora ISO Builder! 🚀