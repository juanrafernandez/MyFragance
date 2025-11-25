# PerfBeta

A sophisticated iOS application for perfume discovery, management, and personalized recommendations.

## Features

- **Olfactive Profile Testing** - Interactive questionnaire to discover your fragrance preferences
- **Personalized Recommendations** - Smart perfume suggestions based on your profile
- **Perfume Library** - Track perfumes you've tried and maintain your wishlist
- **Gift Mode** - Create profiles to find the perfect fragrance gift for others
- **Offline Support** - Full functionality with intelligent caching

## Requirements

- iOS 17.2+
- Xcode 15.0+
- Swift 6.0

## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/juanrafernandez/MyFragance.git
cd MyFragance
```

### 2. Firebase Setup
This app requires Firebase. You'll need to:
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an iOS app with bundle ID `com.testjr.perfBeta`
3. Download `GoogleService-Info.plist` and add it to the `PerfBeta/` directory
4. Enable Authentication (Email/Password, Google, Apple)
5. Create a Firestore database

### 3. Build and Run
```bash
# Open in Xcode
open PerfBeta.xcodeproj

# Or build from command line
xcodebuild -scheme PerfBeta -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

The app follows **MVVM** architecture with Protocol-Oriented Services:

```
Views (SwiftUI) → ViewModels (@MainActor) → Services (Protocols) → Firebase
```

### Key Components
- **AppStartupService** - Centralized startup coordination with caching strategies
- **UnifiedRecommendationEngine** - Modular perfume recommendation system
- **CacheManager** - Actor-based permanent disk cache
- **MetadataIndexManager** - Lightweight perfume index with incremental sync

## Project Structure

```
PerfBeta/
├── App/                    # App entry point
├── Models/                 # Data models (Codable)
├── Services/               # Business logic & Firebase
│   ├── Startup/           # App startup coordination
│   └── Recommendation/    # Recommendation engine
├── ViewModels/            # State management
├── Views/                 # SwiftUI views
│   ├── HomeTab/
│   ├── TestTab/
│   ├── LibraryTab/
│   ├── ExploreTab/
│   └── SettingsTab/
├── Components/            # Reusable UI components
└── Resources/             # Localization, assets
```

## For Claude Code / AI Agents

See [CLAUDE.md](CLAUDE.md) for comprehensive documentation including:
- Detailed architecture overview
- Service layer documentation
- Coding conventions
- Common development tasks
- Firebase structure

## Tech Stack

- **SwiftUI** - Declarative UI
- **Firebase** - Auth, Firestore
- **Kingfisher** - Image caching
- **Combine** - Reactive programming

## License

Private repository. All rights reserved.

---

**Bundle ID:** `com.testjr.perfBeta`
**Version:** 1.0
