# ⚒ Forge

> **Build once. Sign anywhere.**

### The open-source build engine for iOS projects.

Forge is an open-source automation engine that transforms any GitHub iOS repository into a clean, unsigned build—ready to be signed using the tool of your choice.

No Xcode setup.

No manual project configuration.

No complicated build steps.

Just provide a repository, and Forge handles the rest.

---

# ✨ Why Forge?

Building iOS projects outside of Xcode can be frustrating.

Every project is different.

Different project structures.

Different build systems.

Different workspaces.

Different schemes.

Different dependencies.

Forge removes that complexity.

Its mission is simple:

> **Analyze. Detect. Build. Export.**

Signing is **your choice**.

---

# 🚀 Features

- 📥 Clone any public GitHub repository
- 🔍 Automatically detect Xcode Projects and Workspaces
- 🧠 Automatically detect available Schemes
- ⚙️ Prepare the build environment
- 📦 Build iOS projects
- 🗂 Generate Xcode Archives
- 📤 Export unsigned build artifacts
- ☁️ Upload build artifacts using GitHub Actions
- 🧩 Plugin-based architecture (coming soon)
- 🛠 Designed to work entirely from GitHub Actions

---

# 🎯 Philosophy

Forge intentionally separates **building** from **signing**.

Instead of forcing developers into one signing workflow, Forge focuses on building reliable unsigned applications that can later be signed however you prefer.

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
 Unsigned IPA
        │
        ▼
 Feather
 AltStore
 Esign
 Sideloadly
 Apple Configurator
 or any signing solution
```

Forge builds.

You decide how to sign.

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
- Export unsigned IPA
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

Plugin System

Examples:

- 🔐 Signing Plugin
- ☁️ TestFlight Plugin
- 📦 App Store Plugin
- 🧾 Notarization Plugin
- 🧩 Custom Export Plugins

---

# 🏗 Architecture

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

Forge aims to become the universal build engine for iOS projects.

The long-term goal is simple:

Give Forge any GitHub repository and receive a ready-to-sign build without opening Xcode.

Whether you're using GitHub Actions today or another CI platform tomorrow, Forge is designed to remain portable, extensible, and developer-friendly.

---

# ❤️ Open Source

Forge is built for developers who love automation, open-source software, and clean build pipelines.

Whether you:

- Improve project detection
- Support new project structures
- Optimize build workflows
- Create plugins
- Fix bugs
- Improve documentation

Every contribution helps Forge become better for the entire community.

---

# 📄 License

MIT License
