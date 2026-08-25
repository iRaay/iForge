# iForge Workflows

| Workflow | File | Role | Status |
|---|---|---|---|
| iForge Build | `build.yml` | Primary iForge engine, consumed by the ForgeApp iOS client. Supports the Swift Package plugin policy (`allow_package_plugins`). | ✅ Stable |
| iForge Build (app) | `forge-ios-app.yml` | Builds the iForge companion iOS app itself and uploads `iForge-Build.ipa`. | ✅ Stable |

## Notes

- `build.yml` accepts a public GitHub repository (`owner/repo`) plus a branch,
  analyzes it, archives it with Xcode, and uploads an **unsigned** IPA artifact.
- The engine was validated against [claration/Feather](https://github.com/claration/Feather)
  with a clean Release build and Swift Package plugins enabled.
