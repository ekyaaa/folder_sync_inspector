# Folder Sync Inspector

A powerful and modern Flutter Desktop utility designed to validate file synchronization and verify Git commit integrity across folder structures. 

Built with a clean Material 3 design, it provides an efficient workflow for developers and system integrators to ensure that a set of "changes" (Folder A) accurately reflects the state or history of a "project" (Folder B).

## 🧐 Why on earth does this exist?

Imagine you're stuck in a corporate fortress 🏰 where the Local Server is a grumpy giant that refuses to let GitHub in. No fancy PRs, no cloud magic, just raw repo files and local git logs. 

Instead of crying 😭 (or using a USB stick like it's 2005), I built **Folder Sync Inspector**! It's the ultimate "bridging the gap" tool for when you need to verify if the files you're about to deploy actually match what's in that specific Git commit. It's fast, it's pretty, and it works where the internet doesn't. 🚀

## 🚀 Features

- **Folder Compare**: Compare content between two directories using high-speed SHA-256 hashing.
- **Git Check**: Automatically load commits from Folder B and verify if Folder A matches the file list of chosen commits.
- **Visual Diff**: Code-editor style modal for reviewing line-by-line differences with dual line numbers and color-coded changes.
- **Smart Filtering**: Quickly filter results by status (Match, Different, Missing) and real-time path search.
- **Dark/Light Mode**: Full theme support with local persistence for long-term comfort.

---

## 🛠 Workflow: Preparing "Folder A" (Changes)

To use this tool effectively, you often need to generate a directory structure containing only the files changed in a specific Git commit or range. Use these commands to prepare your **Folder A**:

### 1. Extract changed file list from a commit
Run this command in your project repository to output a list of modified/added files (excluding deleted ones):
```bash
git diff-tree --no-commit-id --name-only --diff-filter=d -r {__commit_hash__} > changes.txt
```

### 2. Generate structured folder for comparison
Use this command to copy those files into a new temporary directory while preserving their full directory paths:
```bash
mkdir -p deploy_folder && xargs -a changes.txt cp --parents -t deploy_folder
```
*You can now point **Folder A** in the app to this `deploy_folder` and compare it against your live project in **Folder B**.*

---

## 🏗 Setup & Build

This is a standard Flutter project. Ensure you have the Flutter SDK installed and configured for desktop (Linux/Windows).

### Run in Development
```bash
flutter run
```

### Build Release (Linux)
```bash
flutter build linux
```

### Build Release (Windows)
```bash
flutter build windows
```

## 📦 Dependencies
- `flutter_riverpod`: State management
- `shared_preferences`: Local settings persistence
- `file_selector`: Native file/folder picking
- `diff_match_patch`: Line-based diffing engine
- `google_fonts`: Inter & JetBrains Mono typography
