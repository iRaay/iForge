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
| `docs/PLUGIN_VALIDATION.md` | Swift Package plugin validation guide |

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

- `forge-build.yml` has been consolidated into `build.yml` after validation.

### Swift Package Plugins

When working with projects that use Swift Package build-tool plugins (e.g., `licenseplist`):

- **Detection**: Add plugin detection logic to `analyze.sh` section 8
- **Preservation**: Ensure `FORGE_HAS_PACKAGE_PLUGINS` is preserved in `prepare.sh`
- **Validation**: Implement smart plugin validation bypass in `build.sh`
- **Documentation**: Update `docs/PLUGIN_VALIDATION.md` with new plugin support

**Plugin Detection Checklist:**
- [ ] Detect plugin name in `Package.swift`
- [ ] Set `FORGE_HAS_PACKAGE_PLUGINS="true"` when plugin found
- [ ] Preserve flag through `prepare.sh`
- [ ] Provide clear diagnostic output in `build.sh`
- [ ] Test with and without `FORGE_ALLOW_PACKAGE_PLUGINS=true`
- [ ] Document in `PLUGIN_VALIDATION.md`

### Security

- Source repositories are cloned over HTTPS only. Do not add credential-based cloning
  without discussing it in an issue first.
- Submodule URLs must be credential-free HTTPS (enforced by `prepare_sources.sh`).
- Plugin validation should **default to secure** (validation enabled). Only allow
  bypass when explicitly requested by the user.
- Never hard-code `allow_package_plugins=true` in workflows.

## Testing

Run engine changes against several project shapes before submitting:

- A plain `.xcodeproj` app (no package manager)
- A workspace + CocoaPods app
- An app using Swift Package Manager
- An app with Swift Package plugins (e.g., with `licenseplist`)

### Testing Plugin Support

For plugin-related changes:

1. **Test with plugin detection disabled:**
   ```bash
   FORGE_ALLOW_PACKAGE_PLUGINS=false ./scripts/analyze.sh
   ./scripts/prepare.sh
   ./scripts/build.sh
   ```

2. **Test with plugin bypass enabled:**
   ```bash
   FORGE_ALLOW_PACKAGE_PLUGINS=true ./scripts/analyze.sh
   ./scripts/prepare.sh
   ./scripts/build.sh
   ```

3. **Verify forge.env preservation:**
   ```bash
   cat project/build/forge.env | grep FORGE_HAS_PACKAGE_PLUGINS
   cat project/build/forge.env | grep FORGE_ALLOW_PACKAGE_PLUGINS
   ```

## Common Pitfalls

### forge.env Configuration

❌ **Wrong:** Rewriting forge.env without preserving all variables
```bash
cat > "$CONFIG_FILE" <<EOF
FORGE_BUILD_TYPE="$BUILD_TYPE"
# Missing FORGE_HAS_PACKAGE_PLUGINS!
EOF
```

✅ **Correct:** Preserve all existing settings
```bash
cat > "$CONFIG_FILE" <<EOF
FORGE_BUILD_TYPE="$BUILD_TYPE"
FORGE_HAS_PACKAGE_PLUGINS="${FORGE_HAS_PACKAGE_PLUGINS:-false}"
FORGE_ALLOW_PACKAGE_PLUGINS="${FORGE_ALLOW_PACKAGE_PLUGINS:-false}"
EOF
```

### Plugin Detection

❌ **Wrong:** Only checking project.pbxproj
```bash
grep -l "licenseplist" project.pbxproj
```

✅ **Correct:** Also checking Package.swift
```bash
find . -type f -name "Package.swift" -exec grep -l "licenseplist" {} +
```

### Diagnostic Output

❌ **Wrong:** Generic error messages
```bash
echo "Build failed"
```

✅ **Correct:** Specific, actionable diagnostics
```bash
echo "❌ xcodebuild failed with plugin validation error"
echo "If this project uses Swift Package plugins, try: allow_package_plugins: true"
```

## Pull Request Checklist

Before submitting your PR:

- [ ] Tests pass locally with real projects
- [ ] No hard-coded project-specific paths or names
- [ ] Configuration properly flows through `forge.env`
- [ ] Error messages are clear and actionable
- [ ] Documentation is updated if behavior changed
- [ ] Commit message follows the format: `type(scope): description`

### Commit Message Format

```
type(scope): description

- Bullet point 1
- Bullet point 2

Fixes #123
```

**Types:** `fix`, `feat`, `docs`, `chore`, `refactor`, `test`
**Scope:** `build`, `analyze`, `prepare`, `export`, `plugins`, `app`, etc.

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).

## Need Help?

- 📖 Check [docs/PLUGIN_VALIDATION.md](docs/PLUGIN_VALIDATION.md) for plugin questions
- 🐛 Open an issue with details about the problem
- 💬 Discuss your idea before starting major work
