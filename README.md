# ⚒ Forge

> **Build once. Sign anywhere.**

### The open-source iOS build engine.

Forge is an open-source iOS build pipeline that transforms any GitHub repository into an unsigned iOS application ready for the signing tool of your choice.

No Xcode setup.
No manual project configuration.
No complicated build steps.

Just give Forge a repository, and it does the rest.

---

# ✨ Why Forge?

Building iOS projects outside of Xcode is often complicated.

Different projects use different structures, build systems, workspaces, schemes, and dependencies.

Forge was created to remove that complexity.

Its mission is simple:

> Analyze. Build. Export.

Signing is your choice.

---

# 🚀 Features

- 📥 Clone any public GitHub repository
- 🔍 Automatically detect Xcode Projects and Workspaces
- 🧠 Automatically detect available Schemes
- ⚙️ Prepare the build environment
- 📦 Build iOS projects
- 🗂 Create Xcode Archives
- 📤 Export unsigned build artifacts
- ☁️ Upload build artifacts through GitHub Actions
- 🧩 Plugin-based architecture (future)
- 🛠 Designed to work entirely from GitHub Actions

---

# 🎯 Philosophy

Forge intentionally separates **building** from **signing**.

Instead of forcing developers into a specific signing workflow, Forge focuses on producing a clean build that can later be signed using the tool that best fits their workflow.

```
Git Repository
        │
        ▼
 Analyze
        │
        ▼
 Detect
        │
        ▼
 Prepare
        │
        ▼
 Build
        │
        ▼
 Archive
        │
        ▼
 Export
        │
        ▼
 Unsigned IPA / Build Artifacts
        │
        ▼
 Feather
 AltStore
 Esign
 Sideloadly
 Apple Configurator
 or any signing solution
```

---

# 📦 Current Pipeline

```
Clone Repository
      ↓
Analyze Project
      ↓
Detect Project Structure
      ↓
Prepare Environment
      ↓
Build
      ↓
Archive
      ↓
Export
      ↓
Upload Artifacts
```

---

# 🛣 Roadmap

## Version 1.0

- Repository cloning
- Automatic project detection
- Automatic scheme detection
- Build pipeline
- Archive generation
- Export unsigned artifacts
- GitHub Actions support

---

## Version 2.0

- Intelligent project analysis
- Multi-project support
- Automatic dependency detection
- Build reports
- Configuration files
- Build profiles

---

## Version 3.0

Plugin system

Examples:

- Signing Plugin
- TestFlight Plugin
- App Store Plugin
- Notarization Plugin
- Custom Export Plugins

---

# 🏗 Project Structure

```
Forge/

├── .github/
│   └── workflows/
│
├── scripts/
│   ├── analyze.sh
│   ├── prepare.sh
│   ├── build.sh
│   ├── export.sh
│   └── sign.sh
│
├── templates/
│
├── plugins/
│
├── docs/
│
└── README.md
```

---

# 🌍 Vision

Forge aims to become a universal build engine for iOS projects.

The long-term goal is simple:

Give Forge any GitHub repository and receive a ready-to-sign build without opening Xcode.

---

# ❤️ Open Source

Forge is built for developers who love automation, open-source software, and clean build pipelines.

Contributions are always welcome.

Whether you improve build detection, support new project structures, optimize workflows, or add plugins—you are helping Forge become better for everyone.

---

# 📄 License

MIT License
