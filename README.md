<div align="center">

# ⚒ iForge

> **Build once. Sign anywhere.**

### The open-source build engine for iOS projects.

<a href="README.md">🇬🇧 EN</a> · <a href="README.ar.md">🇸🇦 AR</a>

</div>

---

iForge is an open-source automation engine designed to build supported iOS projects from GitHub repositories and produce an unsigned IPA ready for external signing.

No local Xcode setup.

No Apple Developer account required by iForge.

No certificates or provisioning profiles required by the core build pipeline.

Just provide a GitHub repository and let iForge handle the build process.

---

## ✨ Why iForge?

Building iOS projects outside Xcode can be complicated.

Every project can have different:

- Project structures
- Workspaces
- Schemes
- Dependencies
- Build configurations

iForge is designed to remove as much of that manual work as possible.

Its mission is simple:

> **Analyze. Detect. Build. Export.**

Signing is your choice.

---

## 🚀 Features

- 📥 Clone a GitHub repository
- 🔍 Automatically detect Xcode Projects and Workspaces
- 🧠 Automatically detect available Schemes
- ⚙️ Prepare the build environment
- 📦 Build iOS projects using Xcode command-line tools
- 🗂 Generate Xcode Archives
- 📤 Generate an unsigned IPA
- ☁️ Upload the unsigned IPA as a GitHub Actions artifact
- 🧩 Designed for future plugin support
- 🛠 GitHub Actions based automation

---

## 🎯 Philosophy

iForge intentionally separates **building** from **signing**.

iForge is responsible for preparing and building the application.

The signing process is intentionally kept outside the core build pipeline.

This allows developers to use the signing solution that best fits their workflow.

**iForge builds. You decide how to sign.**

---

## 📦 Current Pipeline

**GitHub Repository**  
↓  
**Clone Repository**  
↓  
**Analyze Project**  
↓  
**Detect Project / Workspace**  
↓  
**Detect Scheme**  
↓  
**Prepare Environment**  
↓  
**Build**  
↓  
**Archive**  
↓  
**Create Unsigned IPA**  
↓  
**Upload Artifact**

---

## ⚡ Quick Start

iForge currently runs through GitHub Actions.

### 1. Open Actions

Open the **Actions** tab in the iForge repository.

### 2. Select iForge

Choose the **iForge** workflow.

### 3. Run the workflow

Select **Run workflow**.

### 4. Enter your repository

Provide the GitHub repository using:

`owner/repository`

For example:

`iRaay/Navi`

### 5. Run iForge

iForge will:

- Clone the repository
- Analyze the project
- Detect the Xcode project or workspace
- Detect available schemes
- Prepare the environment
- Build the iOS project
- Create an Xcode archive
- Generate an unsigned IPA

### 6. Download the result

After the workflow completes, open the workflow artifacts.

The generated IPA is named automatically from the detected `.app` bundle. For example:

`Navi.app` → `Navi.ipa`

`SimpleApp.app` → `SimpleApp.ipa`

`*.app` → `*.ipa`

For the iForge application itself:

`iForge.app` → `iForge-Build.ipa`

The resulting IPA can then be signed using the signing tool of your choice.

---

## 📱 Signing

Signing is intentionally outside iForge's core build pipeline.

The generated unsigned IPA can be passed to compatible signing tools such as:

- Feather
- AltStore
- Esign
- Sideloadly
- Other compatible signing solutions

iForge does not require a signing certificate or provisioning profile to generate the unsigned IPA.

---

## 🔒 Current Status

### iForge v0.1.0

**Stable Baseline**

The first stable working iForge pipeline includes:

- Automatic project detection
- Automatic scheme detection
- Dynamic build configuration
- Xcode archive generation
- Unsigned IPA generation
- GitHub Actions support
- Artifact upload

This release establishes the foundation for future iForge development.

---

## 🛣 Roadmap

### v0.2 — Intelligent Detection

- Improved project detection
- Better workspace handling
- Smarter scheme selection
- Improved dependency detection
- Build diagnostics

### v0.3 — Build Profiles

- Configuration files
- Build profiles
- Debug / Release selection
- Custom build settings
- Improved build reports

### v0.4 — Multi-Project Support

- Multiple Xcode projects
- Multiple workspaces
- Better target detection
- Improved project selection

### v1.0 — iForge Engine

- Stable automation engine
- Reliable project analysis
- Extensible architecture
- Comprehensive documentation
- CI provider abstraction

### Future — Plugin System

Potential plugins include:

- 🔐 Signing
- ☁️ TestFlight
- 📦 App Store
- 🧾 Notarization
- 🧩 Custom export workflows

These features are intentionally kept outside the core build engine.

---

## 🏗 Architecture

The core iForge structure:

- `.github/workflows/` — GitHub Actions workflows
- `scripts/analyze.sh` — Project analysis
- `scripts/prepare.sh` — Environment preparation
- `scripts/build.sh` — iOS build and archive
- `scripts/export.sh` — Unsigned IPA export
- `templates/` — Future build templates
- `plugins/` — Future plugin system
- `docs/` — Project documentation

The core pipeline follows a simple principle:

**Analyze → Prepare → Build → Export**

Each stage has a specific responsibility.

---

## ⚠️ Current Limitations

iForge v0.1.0 is an early stable baseline.

The current release focuses on projects that can be successfully analyzed and built using Apple's Xcode command-line tools.

Some projects may require additional configuration, dependencies, or build settings that are not yet automatically handled by iForge.

Project detection and scheme selection will continue to improve in future releases.

---

## 🌍 Vision

iForge aims to become a portable and extensible build engine for iOS projects.

The long-term goal is simple:

> **Give iForge a GitHub repository and receive a ready-to-sign build without opening Xcode.**

iForge is designed to evolve beyond a single GitHub Actions workflow and eventually support different CI environments and build workflows.

---

## ❤️ Open Source

iForge is built for developers who love automation, open-source software, and clean build pipelines.

Contributions are welcome.

You can help by:

- Improving project detection
- Supporting new project structures
- Improving build workflows
- Adding plugins
- Fixing bugs
- Improving documentation
- Testing iForge with different iOS projects

Every contribution helps iForge become better for the entire community.

---

## 📄 License

MIT License

---

<div align="center">

**⚒ iForge — Build once. Sign anywhere.**

<a href="README.md">🇬🇧 EN</a> · <a href="README.ar.md">🇸🇦 AR</a>

</div>
