# Contributing to iForge

Thank you for your interest in improving iForge! 🛠

## Project Structure

| Path | Purpose |
|---|---|
| `.github/workflows/` | GitHub Actions workflows (see [workflows README](.github/workflows/README.md)) |
| `scripts/analyze.sh` | Project analysis: detects project/workspace/scheme/dependencies |
| `scripts/prepare.sh` | Environment preparation: SPM / CocoaPods / Carthage / mise |
| `scripts/build.sh` | Xcode archive build (unsigned) |
| `scripts/export.sh` | Unsigned IPA creation and validation |
| `scripts/prepare_sources.sh` | Source preparation and submodule security checks |
| `ForgeApp/` | The companion iOS app (SwiftUI) |

## How to Contribute

1. **Open an issue first** for bugs or feature proposals, so we can discuss the approach.
2. Fork the repository and create a feature branch.
3. Keep pull requests focused — one fix or feature per PR.
4. Test your changes with real projects before submitting.

## Development Guidelines

### Shell scripts

- All engine scripts use `#!/bin/bash` with `set -euo pipefail` (or `set -Eeuo pipefail`).
- Never hard-code app names, scheme names, or paths that belong to a specific project.
- Configuration flows through `build/forge.env`: analyze writes it, prepare may update it,
  build and export read it. Any new variable must be written by analyze **and preserved**
  by prepare's rewrite step.
- Prefer explicit failure messages prefixed with `❌` and success steps with `✅`.

### Workflows

- `forge-build.yml` is the active development engine; changes land there first.
- `build.yml` is the stable pipeline consumed by the ForgeApp — avoid breaking changes.

### Security

- Source repositories are cloned over HTTPS only. Do not add credential-based cloning
  without discussing it in an issue first.
- Submodule URLs must be credential-free HTTPS (enforced by `prepare_sources.sh`).

## Testing

Run engine changes against several project shapes before submitting:

- A plain `.xcodeproj` app (no package manager)
- A workspace + CocoaPods app
- An app using Swift Package Manager

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).
