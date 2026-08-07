# 🚀 iOS Builder

> **Build once. Sign anywhere.**
>
> Build any iOS project from GitHub and export an unsigned IPA ready for signing with the tool of your choice.

Build any iOS project from a GitHub repository with zero Xcode setup.

iOS Builder is an open-source automation tool that clones, analyzes, builds, archives, and exports iOS applications into an unsigned IPA package ready for signing with your preferred tool.

The goal is simple:

> Give iOS Builder a GitHub repository, and it will do the heavy work.

---

## ✨ Features

- 📥 Clone any public GitHub repository
- 🔍 Automatically analyze the project structure
- 🧠 Detect Xcode Project or Workspace
- 🎯 Detect available Schemes
- ⚙️ Prepare the build environment
- 📦 Build and archive the application
- 📁 Export build artifacts
- 🚫 No Apple ID required
- 🚫 No Certificates required
- 🚫 No Provisioning Profiles required
- 📤 Ready for external signing (Feather, Esign, AltStore, Sideloadly...)

---

## 🎯 Project Philosophy

iOS Builder is **not** another code-signing tool.

Its purpose is to automate everything **before signing**.

Instead of requiring Xcode, Apple accounts, certificates, and complicated setup, iOS Builder focuses on generating a clean unsigned build that can be signed using any workflow you prefer.

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
 Unsigned IPA
        │
        ▼
 Feather / Esign / AltStore / Sideloadly
```

---

## 📂 Current Pipeline

```
Clone Repository
      ↓
Analyze Project
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

## 🛣 Roadmap

### Version 1.0

- Project Analyzer
- Automatic Scheme Detection
- Automatic Project Detection
- Build
- Archive
- Export Unsigned IPA
- GitHub Actions support

### Version 2.0

- Plugin System
- Automatic Signing (optional plugin)
- TestFlight Plugin
- App Store Plugin
- Custom Build Templates

### Future

- GitLab CI
- Jenkins
- Azure DevOps
- Codemagic
- Local CLI
- Web Dashboard

---

## 🧩 Architecture

```
iOS-Builder/

├── scripts/
├── templates/
├── plugins/
│   ├── signing/
│   ├── testflight/
│   └── appstore/
├── docs/
└── .github/
```

---

## 🤝 Contributing

Contributions are always welcome.

Whether it's fixing bugs, improving build detection, adding new plugins, or supporting more CI providers, every contribution helps make iOS development easier for everyone.

---

## 📜 License

MIT License
