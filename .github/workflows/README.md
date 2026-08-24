# iForge Workflows

| Workflow | File | Role | Status |
|---|---|---|---|
| iForge Build (Engine) | `forge-build.yml` | New engine under active development. Adds Swift Package plugin policy (`allow_package_plugins`). Changes land here first for testing. | 🚧 WIP |
| iForge Build | `build.yml` | Stable pipeline consumed by the ForgeApp iOS client. Kept unchanged while the new engine matures. | ✅ Stable |
| iForge Build (app) | `forge-ios-app.yml` | Builds the iForge companion iOS app itself and uploads `iForge-Build.ipa`. | ✅ Stable |

## Notes

- Both build pipelines accept a public GitHub repository (`owner/repo`) plus a branch,
  analyze it, archive it with Xcode, and upload an **unsigned** IPA artifact.
- The two pipelines will be consolidated once the engine in `forge-build.yml`
  reaches stability.
