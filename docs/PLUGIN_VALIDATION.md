# Swift Package Plugin Validation Guide

## Overview

iForge now includes improved handling for Swift Package build-tool plugins, particularly for packages like `licenseplist` that require special validation handling during the Xcode build process.

## The Problem

Some Swift Package plugins require special handling during the build phase. By default, Xcode validates all build-tool plugins for security. However, certain plugins like `licenseplist` may fail validation when running in automated environments like GitHub Actions if the project structure or plugin configuration doesn't match Xcode's expectations.

### Error Message

```
** ARCHIVE FAILED **
Validate plug-in "LicensePlistBuildTool" in package "licenseplist"
The following build commands failed:
(3 failures)
```

## How iForge Solves This

iForge now uses a three-phase approach to handle package plugins:

### Phase 1: Detection (analyze.sh)
- Automatically detects if a project uses Swift Package Manager
- Scans `Package.swift` for `buildToolPlugins` references
- Specifically detects `licenseplist` and other common plugins
- Sets `FORGE_HAS_PACKAGE_PLUGINS` flag

### Phase 2: Configuration Preservation (prepare.sh)
- Maintains plugin detection status through environment preparation
- Preserves both `FORGE_HAS_PACKAGE_PLUGINS` and `FORGE_ALLOW_PACKAGE_PLUGINS` flags
- Resolves Swift package dependencies with awareness of plugins

### Phase 3: Smart Validation (build.sh)
- Intelligently decides whether to skip plugin validation
- If plugins detected AND user explicitly allows bypass: uses `-skipPackagePluginValidation`
- If plugins detected but user didn't allow bypass: attempts build with default security policy
- Provides clear diagnostic output for plugin-related errors

## Usage

### Automatic Detection (Default)
For most projects, iForge will automatically detect plugins and handle them appropriately:

```bash
# In your workflow, iForge will:
# 1. Detect if project uses plugins
# 2. Attempt build with secure defaults
# 3. If it fails, suggest re-running with allow_package_plugins: true
```

### Explicit Plugin Bypass
If you encounter plugin validation errors, explicitly enable plugin bypass:

```yaml
- name: Build iOS Scheme
  uses: iRaay/iForge@main
  with:
    repository: owner/repo
    branch: main
    allow_package_plugins: true  # Enable plugin validation bypass
```

## Supported Plugins

### licenseplist
- **Purpose**: Automatically generates license information for iOS apps
- **Status**: Fully detected and handled
- **When to use bypass**: If validation fails despite correct setup

### Other Build-Tool Plugins
iForge detects any plugin using Swift's `buildToolPlugins` syntax. If you encounter validation issues:

1. Check the build log for plugin-related errors
2. Ensure plugin dependencies are correctly specified in `Package.swift`
3. If errors persist, enable `allow_package_plugins: true`

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FORGE_HAS_PACKAGE_PLUGINS` | `false` | Automatically set if plugins detected |
| `FORGE_ALLOW_PACKAGE_PLUGINS` | `false` | Explicitly set by workflow input |
| `FORGE_USE_SPM` | `false` | Automatically set if Swift Package Manager detected |

### Workflow Input

```yaml
allow_package_plugins:
  description: "Explicitly allow Swift Package build-tool plugins by skipping Xcode plugin validation"
  required: true
  default: false
  type: boolean
```

## Troubleshooting

### Build Fails with Plugin Validation Error

**Symptom:**
```
error: Unable to validate plug-in "LicensePlistBuildTool"
```

**Solution:**
1. Check that `Package.swift` correctly declares the plugin
2. Verify plugin package versions are compatible with your Swift version
3. Re-run workflow with `allow_package_plugins: true`

### Plugin Detection Not Working

**Symptom:**
iForge doesn't detect your plugin even though it's declared in `Package.swift`

**Why:**
- Plugin must be declared using `.plugin()` in `Package.swift` dependencies
- iForge searches for `buildToolPlugins` keywords

**Solution:**
Ensure your `Package.swift` contains something like:
```swift
.package(url: "https://github.com/...licenseplist", .upToNextMajor(from: "1.0.0")),
```

And in targets:
```swift
.target(
    name: "MyApp",
    plugins: [
        .plugin(name: "LicensePlistBuildTool", package: "licenseplist")
    ]
)
```

### Configuration Not Preserved

**Symptom:**
`FORGE_ALLOW_PACKAGE_PLUGINS` is lost between phases

**Why:**
forge.env might be rewritten without the flag

**Solution:**
This is now handled automatically in `prepare.sh`, which preserves all plugin-related settings. If you still encounter this, check that:
1. `prepare.sh` is running after `analyze.sh`
2. `build/forge.env` is readable in the build phase

## Security Considerations

### Default Behavior (Most Secure)
- By default, iForge keeps Xcode's plugin validation enabled
- Plugins are validated against Apple's security standards
- Users must explicitly opt-in to disable validation

### When to Bypass Validation
Only disable validation if:
1. You control the plugin code
2. You've verified the plugin doesn't include malicious code
3. You understand the security implications

### Best Practices
1. **Always review plugin code** before enabling the bypass
2. **Use specific versions** of plugins rather than `*` or loose version constraints
3. **Monitor plugin updates** for security issues
4. **Test locally first** with the same settings as CI

## Advanced Usage

### Manual Configuration

If automatic detection isn't working, you can manually configure:

```bash
# In your project's build environment
export FORGE_HAS_PACKAGE_PLUGINS="true"
export FORGE_ALLOW_PACKAGE_PLUGINS="true"
```

### Debugging Plugin Detection

Enable verbose output to see what's being detected:

```bash
# This is automatically done in analyze.sh
grep -l "buildToolPlugins" Package.swift
grep -l "licenseplist" Package.swift
```

## Examples

### Example 1: Project with licenseplist

```
Project/
├── Package.swift (contains licenseplist dependency)
├── Sources/
└── Resources/
```

**What iForge does:**
1. ✅ Detects `licenseplist` in Package.swift
2. ✅ Sets `FORGE_HAS_PACKAGE_PLUGINS="true"`
3. ✅ Attempts build with default validation
4. ❌ If validation fails → suggests `allow_package_plugins: true`

### Example 2: Enabling Plugin Bypass

```yaml
name: Build with Plugin Bypass

on: workflow_dispatch

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build iOS App
        run: |
          chmod +x scripts/analyze.sh scripts/prepare.sh scripts/build.sh scripts/export.sh
          FORGE_ALLOW_PACKAGE_PLUGINS=true ./scripts/analyze.sh
          ./scripts/prepare.sh
          ./scripts/build.sh
          ./scripts/export.sh
```

## References

- [Swift Package Manager Documentation](https://developer.apple.com/documentation/packagedescription)
- [Build Tool Plugins](https://www.swift.org/blog/swiftpm-plugins/)
- [LicensePlist GitHub](https://github.com/mono0926/LicensePlist)
- [Xcode Plugin Validation](https://developer.apple.com/forums/thread/671879)

## Contributing

Found an issue with plugin handling? [Open an issue on GitHub](https://github.com/iRaay/iForge/issues) and include:

1. Your `Package.swift` content
2. The full error message from the build log
3. Your workflow configuration
4. Xcode and Swift versions

---

**Last Updated:** August 26, 2026
**Status:** Active & Maintained
