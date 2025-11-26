# PerfBeta - iOS Perfume Discovery App

## Quick Start for Claude Code / AI Agents

**Welcome!** This document provides all the context needed to work on this iOS project effectively.

### Build & Run
```bash
# Build the project
xcodebuild -scheme PerfBeta -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build

# Run tests (if available)
xcodebuild -scheme PerfBeta -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test
```

### Project Info
- **Bundle ID:** `com.testjr.perfBeta`
- **iOS Target:** 17.2+
- **Swift Version:** 6.0
- **Architecture:** MVVM with Protocol-Oriented Services

---

## Project Overview

**PerfBeta** is an iOS app for perfume discovery, management, and recommendations. Key features:

1. **Olfactive Profile Testing** - Interactive questionnaire to discover fragrance preferences
2. **Personalized Recommendations** - AI-powered perfume suggestions based on profile
3. **Perfume Library** - Track tried perfumes and wishlist
4. **Gift Mode** - Create profiles for recommending perfumes to others

---

## Architecture

### Pattern: MVVM + Services

```
Views (SwiftUI)
    ↓ observe
ViewModels (@MainActor, @Published)
    ↓ use
Services (Protocols → Firebase implementations)
    ↓ access
Firebase (Firestore, Auth)
```

### Key Components

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Models** | `PerfBeta/Models/` | Data structures (Codable) |
| **Services** | `PerfBeta/Services/` | Firebase operations, caching |
| **ViewModels** | `PerfBeta/ViewModels/` | Business logic, state |
| **Views** | `PerfBeta/Views/` | UI (SwiftUI) |
| **Components** | `PerfBeta/Components/` | Reusable UI elements |

### Dependency Injection
- `DependencyContainer.shared` provides all services
- ViewModels receive services via initializer injection
- Views receive ViewModels via `@EnvironmentObject`

---

## App Startup Flow (AppStartupService)

The app uses a centralized `AppStartupService` to handle startup logic:

```swift
// Services/Startup/StartupStrategy.swift
enum StartupStrategy {
    case freshInstall      // First launch: download all data
    case partialCache      // Some cached data: load cache + download missing
    case fullCache         // All cached: instant launch + background sync
    case error             // Handle startup errors
}
```

### Startup Flow
1. `ContentView` checks auth state
2. If authenticated → `AppStartupService.determineStrategy()`
3. Based on strategy:
   - `freshInstall`: Show loading → download metadata → ready
   - `fullCache`: Show MainTabView immediately → sync in background
   - `partialCache`: Load cached data → download missing in background

### Cache System
- **CacheManager** (Actor): Permanent disk cache, thread-safe
- **MetadataIndexManager**: Manages lightweight perfume index (~200 bytes/perfume)
- **Incremental Sync**: Only downloads changed data using `updatedAt` timestamps

---

## Key Services

### Authentication (`AuthService`)
- Email/password, Google Sign-In, Apple Sign-In
- Auth state listener updates `AuthViewModel.isAuthenticated`
- Profile auto-creation on first login

### Questions (`QuestionsService`)
- Unified service for all question types
- Supports: olfactive test, gift flow, opinion questions
- Firebase collections: `questions_es` (Spanish), `questions_en` (English)
- Categories: `category_profile` (olfactive test), `category_gift` (gift flow)

### Unified Question Flow System (November 2024)

Both **Profile** and **Gift** flows use the same unified architecture:

```
TestOlfativoTabView
    ├── UnifiedQuestionFlowView (questions UI)
    │       ├── UnifiedQuestion model
    │       ├── UnifiedOption model
    │       └── UnifiedResponse model
    │
    └── UnifiedResultsView (results UI)
            ├── Profile header with family info
            ├── Recommended perfumes list
            └── Save profile functionality
```

**Key Components:**
- `UnifiedQuestionFlowView.swift` - Shared question UI for both flows
- `UnifiedResultsView.swift` - Shared results UI for both flows
- `UnifiedQuestion/Option/Response` - Models in `UnifiedQuestionFlowViewModel.swift`
- `ProfileCalculationEngine.swift` - Converts responses to profile, delegates to recommendation engine

**Question Model Fields:**
- `weight: Int` - Importance for profile calculation (0-3, where 0 = routing/metadata only)
- `families: [String: Int]` - Family scores per option (e.g., `{"woody": 4, "floral": 3}`)
- `questionType: String` - "single_choice", "routing", "autocomplete_notes", etc.

**Flow:**
1. User answers questions → `UnifiedResponse` stored
2. On completion → `handleProfileCompletion()` or `handleGiftCompletion()`
3. `ProfileCalculationEngine.generateProfile()` converts to `UnifiedProfile`
4. Engine calculates family scores: `Σ(option.families[family] × question.weight)`
5. `UnifiedResultsView` displays profile + recommendations

### Recommendations (`UnifiedRecommendationEngine`)
Modular recommendation system in `Services/Recommendation/`:
- `WeightProfile.swift` - Weight configurations
- `RecommendationFilters.swift` - Filtering logic
- `RecommendationScoring.swift` - Scoring algorithms
- `ProfileCalculationHelpers.swift` - Profile utilities

### Cache (`CacheManager`, `MetadataIndexManager`)
- Reduces Firestore reads by 99.77% after first launch
- Permanent cache with incremental background sync
- Actor-based for thread safety

---

## Project Structure

```
PerfBeta/
├── App/
│   └── PerfBetaApp.swift              # Entry point, Firebase config
├── Models/
│   ├── Perfume.swift                  # Full perfume model (~2KB)
│   ├── PerfumeMetadata.swift          # Lightweight index model (~200B)
│   ├── User.swift                     # User profile
│   ├── OlfactiveProfile.swift         # Test results
│   ├── Question.swift                 # Test questions
│   └── Enums/                         # Gender, Intensity, etc.
├── Services/
│   ├── Startup/
│   │   ├── AppStartupService.swift    # Startup coordinator
│   │   └── StartupStrategy.swift      # Startup strategies
│   ├── Recommendation/
│   │   ├── WeightProfile.swift        # Weight configs
│   │   ├── RecommendationFilters.swift
│   │   ├── RecommendationScoring.swift
│   │   └── ProfileCalculationHelpers.swift
│   ├── AuthService.swift              # Authentication
│   ├── QuestionsService.swift         # Questions (unified)
│   ├── CacheManager.swift             # Disk cache
│   └── MetadataIndexManager.swift     # Perfume metadata index
├── ViewModels/
│   ├── AuthViewModel.swift            # Auth state
│   ├── UserViewModel.swift            # User data
│   ├── PerfumeViewModel.swift         # Perfumes
│   ├── TestViewModel.swift            # Olfactive test
│   ├── GiftRecommendationViewModel.swift  # Gift flow state
│   └── UnifiedQuestionFlowViewModel.swift # Unified question models
├── Views/
│   ├── ContentView.swift              # Root (auth routing)
│   ├── MainTabView.swift              # Tab navigation
│   ├── UnifiedQuestionFlowView.swift  # Shared question UI (Profile & Gift)
│   ├── UnifiedResultsView.swift       # Shared results UI (Profile & Gift)
│   ├── HomeTab/                       # Home screen
│   ├── TestTab/                       # Olfactive test & Gift flow
│   │   ├── TestOlfativoTabView.swift  # Main test tab (launches flows)
│   │   ├── ProfileManagementView.swift # Manage saved profiles
│   │   └── SaveProfileView.swift      # Save profile bottom sheet
│   ├── LibraryTab/                    # Perfume library
│   ├── ExploreTab/                    # Browse/filter
│   └── SettingsTab/                   # Settings
├── Components/                        # Reusable UI
├── Helpers/                           # Utilities
└── Resources/
    └── Localizable.xcstrings          # Spanish localization
```

---

## Firebase Structure

### Collections
| Collection | Description |
|------------|-------------|
| `users/{userId}` | User profiles |
| `perfumes` | Perfume catalog (5,587 docs) |
| `questions` | Test questions (all types) |
| `brands` | Brand info |
| `families` | Olfactive families |
| `tried_perfumes/{userId}/records` | User's tried perfumes |
| `wishlist/{userId}/items` | User's wishlist |
| `olfactive_profiles/{userId}/profiles` | User's test profiles |

### Question Structure in `questions_es` / `questions_en`

Questions are organized by `category`:
- `category_profile` - Olfactive profile test questions
- `category_gift` - Gift recommendation flow questions

**Key fields per question:**
```javascript
{
  id: "gift_A1_personality",
  text: "¿Cómo describirías su personalidad?",
  category: "category_gift",
  flow: "flow_A",           // Flow routing
  weight: 3,                // Importance (0-3)
  questionType: "single_choice",
  options: [
    {
      id: "1",
      label: "Elegante",
      value: "elegant",
      families: { "floral": 4, "woody": 4, "oriental": 2 },
      metadata: { personality: ["elegant", "confident"] }
    }
  ]
}
```

---

## Coding Conventions

### Swift Style
- Use `async/await` for all async operations
- `@MainActor` on all ViewModels
- `#if DEBUG` for all print statements
- Prefer `struct` over `class` for models

### Naming
- Services: `XxxService` (protocol: `XxxServiceProtocol`)
- ViewModels: `XxxViewModel`
- Views: Descriptive name + `View` suffix

### MVVM Rules
- Views observe ViewModels via `@EnvironmentObject`
- ViewModels publish state via `@Published`
- Services are stateless (except caching)
- Models are pure data (Codable structs)

---

## Common Tasks

### Adding a New Feature
1. Create model in `Models/` if needed
2. Add service in `Services/` with protocol
3. Create ViewModel in `ViewModels/`
4. Build views in `Views/`
5. Inject via `@EnvironmentObject` in `PerfBetaApp`

### Adding New Questions to Profile or Gift Flow
1. Add questions to Firebase (`questions_es` collection) with correct `category`
2. Set `weight` (0-3) for importance in profile calculation
3. Add `families` to each option with family scores
4. Increment `currentCacheVersion` in `QuestionsService.swift` to force cache refresh
5. The unified flow will automatically pick up new questions

### Modifying Profile Calculation
1. Check `ProfileCalculationEngine.swift` for conversion logic
2. Check `QuestionProcessor.swift` for score calculation
3. Check `UnifiedRecommendationEngine.swift` for final profile generation
4. All use `weight × families[family]` formula

### Modifying Startup Logic
1. Check `AppStartupService.swift` for strategy changes
2. Update `StartupStrategy.swift` if adding new strategies
3. Modify `ContentView.swift` if changing UI states

### Debugging Cache Issues
```swift
// Clear all caches (in DEBUG)
await AppStartupService.shared.clearUserCache(userId: userId)
```

---

## Testing

### SwiftUI Previews
Most views have `#Preview` blocks using `MockData.swift`

### Manual Testing
1. Build and run on simulator
2. Test auth flows (email, Google, Apple)
3. Test offline behavior (Firestore has offline persistence)

---

## Important Notes

### Security
- `GoogleService-Info.plist` contains Firebase config (gitignored in public repos)
- Never commit `firebase-credentials.json` or `serviceAccountKey.json`
- Auth tokens managed by Firebase SDK

### Performance
- First launch downloads ~5,600 perfume metadata documents
- Subsequent launches use cache (0 Firestore reads)
- Background sync happens every 5 minutes if app is open

### Localization
- Primary language: Spanish (es)
- All strings in `Localizable.xcstrings`

---

## Dependencies

### Swift Package Manager
- **Firebase** (Auth, Firestore)
- **GoogleSignIn**
- **Kingfisher** (Image caching: 50MB memory, 200MB disk)

---

## Quick Reference

### Key Files to Know
| File | Purpose |
|------|---------|
| `ContentView.swift` | App routing (auth → main) |
| `AppStartupService.swift` | Startup coordination |
| `AuthViewModel.swift` | Auth state management |
| `UserViewModel.swift` | User data & library |
| `QuestionsService.swift` | All question fetching |
| `UnifiedRecommendationEngine.swift` | Recommendation logic |

### Debug Tips
- All logs wrapped in `#if DEBUG`
- Look for emoji prefixes: 🚀 startup, ✅ success, ❌ error, ⚠️ warning

---

**Last Updated:** November 2025
**Maintained by:** Claude Code
