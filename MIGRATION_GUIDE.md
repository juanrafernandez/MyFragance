# Migration Guide - Working on Another Machine

**Last Updated:** December 2024  
**For:** Juan Ra Fernández (juanra.fernandez@gmail.com)

---

## 🚀 Quick Start on New Machine

### Step 1: Clone Repository
```bash
cd ~/Documentos/GitHub/MyFragance
```

### Step 2: Open Project in Xcode
```bash
open PerfBeta.xcodeproj
```

### Step 3: Configure Git User
```bash
git config user.email "juanra.fernandez@gmail.com"
git config user.name "Juan Ra Fernández"
```

### Step 4: Verify Dependencies
- Xcode will automatically fetch Swift Package Manager dependencies
- Wait for packages to resolve (Firebase, Kingfisher, etc.)

### Step 5: Build and Run
- Select target: PerfBeta
- Select device: iPhone 16 Pro (or any iOS 17.2+ simulator)
- Press ⌘R to build and run

---

## 📚 Essential Files to Read First

### 1. **CLAUDE.md** - Project Overview
- Complete project documentation
- Architecture and design patterns
- **NEW:** Infinite Cache System documentation
- **NEW:** ExploreTab optimization details
- All features and data models

### 2. **RECENT_CHANGES.md** - What's New
- Summary of December 2024 work
- Performance improvements (99.77% Firestore reduction)
- Bug fixes and optimizations
- Git commit history

### 3. **TODO.md** - What's Next
- High priority tasks
- Known issues
- Future enhancements
- Technical debt

---

## 🔧 Development Environment Setup

### Required Tools
- **Xcode:** 15.0+ (with iOS 17.2+ SDK)
- **macOS:** 14.0+ (Sonoma or later)
- **Git:** 2.30+
- **CocoaPods:** Not required (using SPM)

### Recommended Tools
- **Claude Code:** For AI-assisted development
- **Fork/Sourcetree:** For Git GUI
- **Reveal/SwiftUI Inspector:** For UI debugging

### Firebase Configuration
- Project already has `GoogleService-Info.plist`
- Firebase project: `perfbeta`
- No additional setup needed
- API keys are NOT in repository (.gitignore)

---

## 🗂️ Project Structure Quick Reference

```
PerfBeta/
├── CLAUDE.md              ← Read this first!
├── RECENT_CHANGES.md      ← What changed recently
├── TODO.md                ← What to do next
├── MIGRATION_GUIDE.md     ← You are here
│
├── PerfBeta/
│   ├── App/               ← App entry point
│   ├── Models/            ← Data models
│   │   ├── Perfume.swift
│   │   └── PerfumeMetadata.swift  ← NEW: Lightweight model
│   │
│   ├── Services/          ← Business logic
│   │   ├── CacheManager.swift     ← NEW: Permanent cache
│   │   ├── MetadataIndexManager.swift ← NEW: Metadata sync
│   │   └── PerfumeService.swift
│   │
│   ├── ViewModels/        ← MVVM ViewModels
│   │   └── PerfumeViewModel.swift
│   │
│   └── Views/             ← SwiftUI views
│       ├── ExploreTab/    ← Recently optimized!
│       ├── HomeTab/       ← Recently optimized!
│       └── ...
```

---

## 🎯 Current State of Project

### ✅ Completed (December 2024)
- Infinite cache system (99.77% Firestore reduction)
- Metadata index with incremental sync
- ExploreTab optimization (instant filtering)
- HomeTab optimization (lazy loading)
- Family filter fix (displayName → key mapping)
- Case-insensitive filtering
- Comprehensive documentation

### 🔄 In Progress
- None (all work committed)

### 📋 Next Tasks (See TODO.md)
- Remove debug logging for production
- Add cache clearing in Settings
- Write unit tests for CacheManager
- Test on physical devices

---

## 🐛 Known Issues

### Non-Critical (Can Ignore)
1. **Xcode Breakpoints File Modified**
   - File: `*.xcbkptlist`
   - Reason: User-specific debug data
   - Solution: Already in .gitignore, safe to ignore

2. **onChange Deprecation Warnings**
   - Lines: ExploreTabView.swift:126, 235
   - Reason: iOS 17+ requires new onChange syntax
   - Solution: TODO - update to new syntax

3. **Debug Logging is Verbose**
   - Location: ExploreTabView.swift filterResults()
   - Reason: Intentional for troubleshooting
   - Solution: Remove/comment out before production

### Critical (Must Fix Before Production)
- None currently

---

## 📊 Performance Expectations

### First App Launch (Cold Start)
- **Time:** ~2-3 seconds
- **Firestore reads:** ~5,657 (metadata index + initial data)
- **Disk cache:** Creates ~200KB metadata cache
- **Expected:** This is normal, one-time cost

### Subsequent Launches (Warm Start)
- **Time:** ~0.1-0.2 seconds
- **Firestore reads:** 0 (loads from cache)
- **Network:** Background sync for changed data only
- **Expected:** Instant startup ✨

### ExploreTab Filtering
- **Time:** Instant (in-memory)
- **Works offline:** Yes (uses cached metadata)
- **Firestore reads:** 0 (until you view perfume details)

---

## 🔑 Important Code Patterns

### Loading Metadata (App Startup)
```swift
// MainTabView.swift
await perfumeViewModel.loadMetadataIndex()
```

### Getting Recommendations (HomeTab)
```swift
// Uses metadata for scoring, downloads only top results
let recommendations = try await perfumeViewModel.getRelatedPerfumes(
    for: profile,
    from: families
)
```

### Filtering Perfumes (ExploreTab)
```swift
// Filters happen in-memory on perfumeViewModel.perfumes
// Uses familyNameToKey mapping for family filters
let matchesFamily = selectedFilters["Familia Olfativa"].map { ... }
```

---

## 🧪 Testing Checklist

### Before Making Changes
1. Run app and verify it builds
2. Check ExploreTab filters work
3. Verify HomeTab recommendations load
4. Test clean install (delete app, reinstall)

### After Making Changes
1. Build succeeds without errors
2. No new warnings (or document them)
3. Test affected features manually
4. Run on simulator + physical device (if possible)

---

## 📝 Git Workflow

### Current Status
- **Branch:** main
- **Commits ahead:** 32 (including documentation)
- **Last commit:** a673512 (.gitignore update)

### Before Starting Work
```bash
git status           # Check current state
git log --oneline -10  # Review recent commits
git pull origin main # Get latest changes (after push)
```

### After Making Changes
```bash
git status           # See what changed
git add <files>      # Stage changes
git commit -m "..."  # Commit with descriptive message
git push origin main # Push to remote
```

### Commit Message Format
```
<type>: <subject>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `chore`: Maintenance (dependencies, config)
- `refactor`: Code restructuring
- `test`: Adding tests
- `perf`: Performance improvement

---

## 🔐 Authentication & Secrets

### Git Authentication
```bash
# Use Personal Access Token (not password)
git remote set-url origin https://YOUR_TOKEN@github.com/juanrafernandez/MyFragance.git
```

### Firebase
- Already configured in `GoogleService-Info.plist`
- No additional auth needed
- Test user: Create via app or Firebase Console

---

## 💡 Tips for Claude Code

When starting work with Claude Code:

1. **First Prompt:**
   ```
   I'm continuing work on PerfBeta. Please read CLAUDE.md, 
   RECENT_CHANGES.md, and TODO.md to get context.
   ```

2. **For New Features:**
   ```
   I want to add [feature]. Check TODO.md for related items,
   and follow the patterns in CLAUDE.md.
   ```

3. **For Bug Fixes:**
   ```
   I found a bug: [description]. Check RECENT_CHANGES.md
   to see if this was recently modified.
   ```

4. **Before Committing:**
   ```
   Review my changes and create a commit message following
   the format in MIGRATION_GUIDE.md.
   ```

---

## 📞 Need Help?

### Documentation Locations
- **Project Overview:** CLAUDE.md
- **Recent Changes:** RECENT_CHANGES.md
- **Pending Tasks:** TODO.md
- **This Guide:** MIGRATION_GUIDE.md

### Common Issues
1. **Build Fails:** Clean build folder (⌘⇧K), restart Xcode
2. **Dependencies Missing:** File > Packages > Resolve Package Versions
3. **Simulator Crash:** Reset simulator content & settings
4. **Cache Issues:** Delete app, clean build, reinstall

### Useful Commands
```bash
# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset git to last commit
git reset --hard HEAD

# See what changed since last push
git diff origin/main

# Undo last commit (keep changes)
git reset --soft HEAD~1
```

---

## ✅ You're Ready!

Everything is set up and documented. The project is in excellent shape:
- ✅ All code committed
- ✅ Comprehensive documentation
- ✅ Clear next steps
- ✅ Known issues documented
- ✅ Performance optimized

**Next Step:** Clone the repository and start coding! 🚀

---

**Author:** Juan Ra Fernández  
**Email:** juanra.fernandez@gmail.com  
**Date:** December 2024  
**Project:** PerfBeta (MyFragance iOS App)
