# PerfBeta - Comprehensive Project Documentation

## 📱 Project Overview

**PerfBeta** is a sophisticated iOS application for perfume discovery, management, and recommendations. The app combines olfactive profile testing, personalized recommendations, a perfume library, and social features to help users discover and manage their fragrance journey.

**Bundle ID:** `com.testjr.perfBeta`
**Version:** 1.0 (Build 1)
**Target iOS:** 17.2+
**Swift Version:** 6.2
**App Type:** Native iOS (SwiftUI)

---

## 🏗️ Architecture & Design Patterns

### Architecture
- **MVVM (Model-View-ViewModel)** - Clean separation of concerns
- **Protocol-Oriented Design** - All services implement protocols for testability
- **Dependency Injection** - Centralized via `DependencyContainer`
- **Observable Pattern** - Using SwiftUI's `@StateObject` and `@EnvironmentObject`

### State Management
- **Environment Objects** - Global state shared across views
- **AppState** - Centralized app-level state management
- **AuthViewModel** - Manages authentication state and user session

---

## 📁 Project Structure

```
PerfBeta/
├── App/
│   ├── PerfBetaApp.swift           # Main app entry point, Firebase config
│   └── LaunchScreen.storyboard     # Launch screen
├── Models/
│   ├── Perfume.swift               # Core perfume data model
│   ├── User.swift                  # User account model
│   ├── OlfactiveProfile.swift      # Olfactive profile with recommendations
│   ├── TriedPerfumeRecord.swift    # User's tried perfume records
│   ├── WishlistItem.swift          # Wishlist item model
│   ├── Brand.swift                 # Brand model
│   ├── Family.swift                # Olfactive family model
│   ├── Question.swift              # Test question model
│   ├── QuestionAnswer.swift        # Question-answer pairing
│   ├── Perfumist.swift             # Perfume creator/nose model
│   ├── NotesNotes.swift            # Fragrance notes model
│   └── Enums/
│       ├── Gender.swift            # Gender categories
│       ├── Intensity.swift         # Fragrance intensity levels
│       ├── Duration.swift          # Fragrance longevity
│       ├── Projection.swift        # Sillage/projection strength
│       ├── Price.swift             # Price ranges
│       ├── Season.swift            # Recommended seasons
│       ├── Occasion.swift          # Usage occasions
│       ├── Personality.swift       # Personality types
│       └── Country.swift           # Country references
├── Services/
│   ├── AuthService.swift           # Firebase Authentication
│   ├── UserService.swift           # User data management
│   ├── PerfumeService.swift        # Perfume data operations
│   ├── OlfactiveProfileService.swift # Olfactive profile operations
│   ├── BrandService.swift          # Brand data operations
│   ├── FamilyService.swift         # Family data operations
│   ├── NotesService.swift          # Notes data operations
│   ├── PerfumistService.swift      # Perfumist data operations
│   ├── QuestionsService.swift      # Test questions service
│   ├── TestService.swift           # Olfactive test service
│   └── CloudinaryService.swift     # Image hosting service
├── ViewModels/
│   ├── AuthViewModel.swift         # Authentication state & logic
│   ├── UserViewModel.swift         # User profile management
│   ├── PerfumeViewModel.swift      # Perfume data & operations
│   ├── OlfactiveProfileViewModel.swift # Profile management
│   ├── BrandViewModel.swift        # Brand data management
│   ├── FamilyViewModel.swift       # Family data management
│   ├── NotesViewModel.swift        # Notes data management
│   ├── PerfumistViewModel.swift    # Perfumist data management
│   ├── TestViewModel.swift         # Olfactive test logic
│   ├── QuestionsViewModel.swift    # Questions management
│   └── FilterViewModel.swift       # Filter/search logic
├── Views/
│   ├── ContentView.swift           # Root view (auth routing)
│   ├── MainTabView.swift           # Main tab navigation
│   ├── Login/
│   │   ├── LoginView.swift         # Login screen
│   │   ├── SignUpView.swift        # Registration screen
│   │   ├── GoogleLoginButton.swift # Google sign-in button
│   │   └── CurvedHeaderShape.swift # Custom UI shape
│   ├── HomeTab/
│   │   ├── HomeTabView.swift       # Home screen
│   │   ├── ProfileCard.swift       # Olfactive profile cards
│   │   ├── GreetingSection.swift   # User greeting section
│   │   ├── PerfumeCarouselItem.swift # Perfume carousel card
│   │   ├── PerfumeHorizontalListView.swift # Horizontal perfume list
│   │   ├── AllPerfumesView.swift   # All perfumes grid
│   │   └── HomeDidYouKnowSectionView.swift # Tips section
│   ├── ExploreTab/
│   │   └── ExploreTabView.swift    # Explore/discover screen
│   ├── TestTab/
│   │   ├── TestOlfativoTabView.swift # Olfactive test main screen
│   │   ├── TestView.swift          # Test questionnaire
│   │   ├── TestResultView.swift    # Test results display
│   │   ├── TestResultContentView.swift # Results content
│   │   ├── TestResultNavigationView.swift # Results navigation
│   │   ├── TestResultFullScreenView.swift # Full screen results
│   │   ├── TestSaveProfileView.swift # Save profile dialog
│   │   ├── ProfileManagementView.swift # Manage profiles
│   │   ├── SuggestionsView.swift   # Perfume suggestions
│   │   ├── TestRecommendedPerfumesView.swift # Recommendations
│   │   ├── ProfileCardView.swift   # Profile card component
│   │   ├── TestProfileHeaderView.swift # Profile header
│   │   ├── TestPerfumeCardView.swift # Perfume card
│   │   ├── SummaryView.swift       # Test summary
│   │   ├── GiftView.swift          # Gift profile mode
│   │   └── GiftSummaryView.swift   # Gift summary
│   ├── LibraryTab/
│   │   ├── FragranceLibraryTabView.swift # Library main view
│   │   ├── TriedPerfumesListView.swift # Tried perfumes list
│   │   ├── WishlistListView.swift  # Wishlist
│   │   ├── ImpressionsView.swift   # User impressions editor
│   │   ├── FraganceLibraryTabSections/ # Library sections
│   │   ├── Share/                  # Share functionality
│   │   │   └── (share views)
│   │   └── TriedPerfumesSteps/     # Add perfume wizard
│   │       ├── AddPerfumeOnboardingView.swift
│   │       ├── AddPerfumeInitialStepsView.swift
│   │       ├── AddPerfumeStep2View.swift
│   │       └── (other step views)
│   ├── PerfumeDetail/
│   │   ├── PerfumeDetailView.swift # Perfume detail screen
│   │   └── PerfumeCardView.swift   # Perfume card component
│   ├── Filter/
│   │   ├── PerfumeFilterView.swift # Filter interface
│   │   └── FilterablePerfumeItem.swift # Filterable item
│   └── SettingsTab/
│       └── SettingsView.swift      # Settings screen
├── Components/
│   ├── GradientBackgroundView.swift # Reusable gradient background
│   ├── ItsukiSlider.swift          # Custom slider component
│   ├── AccordionView.swift         # Accordion/expandable view
│   └── ButtonStyle.swift           # Custom button styles
├── Helpers/
│   ├── DependencyContainer.swift   # DI container (singleton)
│   ├── AppState.swift              # Global app state
│   ├── OlfactiveProfileHelper.swift # Profile utilities
│   └── IdentifiableString.swift   # String wrapper for SwiftUI
├── Utils/
│   ├── GradientPreset.swift        # Gradient color definitions
│   ├── TextStyle.swift             # Text style helpers
│   ├── ButtonsStyle.swift          # Button style definitions
│   ├── AuthUtils.swift             # Auth utility functions
│   └── MockData.swift              # Mock data for previews
├── Extensions/
│   ├── CollectionExtension.swift   # Collection helpers
│   ├── ArrayExtension.swift        # Array utilities
│   └── UIColorExtension.swift      # Color extensions
├── Resources/
│   └── Localizable.xcstrings       # Localization strings
├── Assets.xcassets/                # Images and colors
│   ├── AppIcon.appiconset/
│   ├── Colors/                     # Color assets
│   ├── Images/
│   ├── Duration/                   # Duration images
│   ├── Family/                     # Family images
│   ├── Gender/                     # Gender images
│   ├── Intensity/                  # Intensity images
│   ├── Occasion/                   # Occasion images
│   ├── Personality/                # Personality images
│   ├── Price/                      # Price images
│   ├── Projection/                 # Projection images
│   ├── Season/                     # Season images
│   ├── Questions/                  # Question images
│   └── FraganciasHombre/           # Sample perfume images
├── GoogleService-Info.plist        # Firebase configuration
└── Info.plist                      # App configuration
```

---

## 🔥 Technology Stack

### Core Technologies
- **Swift 6.2**
- **SwiftUI** - Declarative UI framework
- **Combine** - Reactive programming

### Firebase Services
- **Firebase Core** - SDK initialization
- **Firebase Authentication** - User authentication
  - Email/Password
  - Google Sign-In
  - Apple Sign In
- **Cloud Firestore** - NoSQL database with offline persistence
- **Firebase Storage** - File storage (via Cloudinary)

### Third-Party Libraries
- **Kingfisher** - Async image loading and caching
  - Memory cache: 50 MB
  - Disk cache: 200 MB
- **GoogleSignIn** - Google authentication SDK
- **Cloudinary** (service layer) - Image CDN

### iOS Frameworks
- **AuthenticationServices** - Sign in with Apple
- **CryptoKit** - Cryptographic operations (Apple Sign-In nonce)

---

## 🔑 Key Features Implemented

### 1. Authentication System
✅ **Email/Password Registration & Login**
✅ **Google Sign-In Integration**
✅ **Apple Sign-In Integration**
✅ **Auth State Management** - Listener-based session handling
✅ **Profile Creation** - Automatic Firestore profile creation
✅ **Social Auth Validation** - Login vs Register flow distinction
✅ **Error Handling** - Comprehensive error mapping

**Auth Flow:**
- User authenticates → Firebase Auth validates → `checkAndCreateUserProfileIfNeeded()`
- Login: Verifies profile exists, updates lastLoginAt
- Register: Creates new Firestore user document
- Auth state listener automatically updates UI

### 2. Olfactive Profile System
✅ **Interactive Questionnaire** - Multi-step test with visual elements
✅ **Profile Generation** - AI/algorithm-based profile creation
✅ **Multiple Profiles** - Users can save multiple profiles
✅ **Gift Mode** - Create profiles for others
✅ **Profile Management** - Edit, delete, reorder profiles
✅ **Personalized Recommendations** - Perfume matches based on profile

**Profile Structure:**
- Family preferences with scoring (FamilyPuntuation)
- Intensity and duration preferences
- Question-answer history
- Recommended perfumes with match percentages

### 3. Perfume Library (Mi Colección)
✅ **Tried Perfumes** - Track perfumes you've tried
✅ **Wishlist** - Save perfumes you want to try
✅ **Multi-step Add Flow** - Wizard for adding perfumes
✅ **Custom Reviews** - Rating, impressions, occasions, seasons
✅ **Image Support** - Perfume bottle images
✅ **Filtering & Sorting** - Organize your collection

**TriedPerfumeRecord Fields:**
- Personal ratings (1-5 stars)
- Projection, duration, price assessments
- Custom impressions/notes
- Occasions, seasons, personalities tags

### 4. Home & Discovery
✅ **Personalized Home Feed** - Dynamic content based on profiles
✅ **Perfume Carousels** - Horizontal scrolling lists
✅ **Profile Cards** - Quick access to olfactive profiles
✅ **"Did You Know?" Section** - Educational content
✅ **All Perfumes View** - Browse entire catalog

### 5. Explore & Filter
✅ **Advanced Filtering** - Multi-criteria perfume search
✅ **Filter Categories:**
  - Gender (Male, Female, Unisex)
  - Family (Woody, Floral, Aquatic, Spicy, Gourmand)
  - Intensity, Duration, Projection
  - Price Range
  - Season, Occasion, Personality

### 6. Perfume Detail View
✅ **Comprehensive Information Display**
  - Notes pyramid (top, heart, base)
  - Brand & perfumist info
  - Characteristics (intensity, duration, etc.)
  - User actions (add to tried/wishlist)

### 7. Settings
✅ **Account Management**
✅ **Sign Out Functionality**
✅ **App Preferences**

---

## 🗄️ Data Models

### Core Models

**Perfume**
```swift
struct Perfume: Identifiable, Codable {
    var id: String
    var name: String
    var brand: String
    var key: String
    var family: String
    var subfamilies: [String]
    var topNotes: [String]?
    var heartNotes: [String]?
    var baseNotes: [String]?
    var projection: String
    var intensity: String
    var duration: String
    var recommendedSeason: [String]
    var associatedPersonalities: [String]
    var occasion: [String]
    var popularity: Double
    var year: Int
    var perfumist: String?
    var imageURL: String?
    var description: String
    var gender: String
    var price: String?
    var createdAt: Date?
    var updatedAt: Date?
}
```

**User**
```swift
struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var preferences: [String: String]
    var favoritePerfumes: [String]
    var triedPerfumes: [String]
    var wishlistPerfumes: [String]
    var createdAt: Date?
    var updatedAt: Date?
    var lastLoginAt: Date?
}
```

**OlfactiveProfile**
```swift
struct OlfactiveProfile: Identifiable, Codable {
    var id: String?
    var name: String
    var gender: String
    var families: [FamilyPuntuation]
    var intensity: String
    var duration: String
    var descriptionProfile: String?
    var icon: String?
    var questionsAndAnswers: [QuestionAnswer]?
    var recommendedPerfumes: [RecommendedPerfume]?
    var orderIndex: Int
}
```

**TriedPerfumeRecord**
```swift
struct TriedPerfumeRecord: Codable, Identifiable {
    var id: String?
    let userId: String
    let perfumeId: String
    let perfumeKey: String
    let brandId: String
    var projection: String
    var duration: String
    var price: String
    var rating: Double?
    var impressions: String?
    var occasions: [String]?
    var seasons: [String]?
    var personalities: [String]?
    var createdAt: Date?
    var updatedAt: Date?
}
```

---

## 🎨 Design System

### Color Palette
**Primary Colors:**
- `primaryChampagne` - Main brand color (champagne gold)
- `Gold` - Accent color

**Neutral Colors:**
- `textoPrincipal` - Primary text
- `textoSecundario` - Secondary text
- `textoInactivo` - Disabled/inactive text
- `fondoClaro` - Light background
- `grisClaro`, `grisSuave` - Gray variations

**Family Colors:**
- `amaderadosClaro` - Woody
- `floralesClaro` - Floral
- `acuáticosClaro` - Aquatic
- `orientalesClaro` - Oriental
- `cítricosClaro` - Citrus
- `verdesClaro` - Green

**Button Colors:**
- `PrimaryButtonColor`
- `SecondaryButtonBackgroundColor`
- `SecondaryButtonBorderColor`
- `ButtonTextColor`

### Typography
- Custom text styles defined in `TextStyle.swift`
- System fonts with custom sizing

### Gradients
- `GradientPreset.swift` contains reusable gradient definitions
- `GradientBackgroundView` for consistent backgrounds

---

## 🔐 Firebase Structure

### Firestore Collections

**users/** - User profiles
```
users/{userId}
  - uid: String
  - nombre: String
  - email: String
  - rol: String (default: "usuario")
  - preferences: Map<String, String>
  - favoritePerfumes: Array<String>
  - triedPerfumes: Array<String>
  - wishlistPerfumes: Array<String>
  - createdAt: Timestamp
  - updatedAt: Timestamp
  - lastLoginAt: Timestamp
```

**perfumes/** - Perfume catalog (assumed)
**brands/** - Brand information
**families/** - Olfactive families
**notes/** - Fragrance notes
**perfumists/** - Perfume creators
**questions/** - Test questions
**olfactive_profiles/** - User olfactive profiles
**tried_perfumes/** - User tried perfume records
**wishlist/** - User wishlist items

---

## 🧩 Service Layer

All services follow **Protocol-Oriented Architecture**:

### AuthService
- User registration (email/password)
- Sign in (email/password, social)
- Sign out
- Profile verification and creation
- Auth state listening

### UserService
- Fetch user profile
- Update user data
- Manage favorites, tried list, wishlist

### PerfumeService
- Fetch perfumes (by ID, filters, search)
- Cache management

### OlfactiveProfileService
- Create/update/delete profiles
- Fetch user profiles
- Generate recommendations

### BrandService / FamilyService / NotesService
- Fetch and cache reference data

### QuestionsService / TestService
- Load test questions
- Process test results

---

## 📊 ViewModel Architecture

All ViewModels are:
- `@MainActor` annotated (for UI thread safety)
- `ObservableObject` conforming
- Use `@Published` properties for reactive UI
- Injected with service protocols

### Key ViewModels

**AuthViewModel**
- Manages authentication state
- Handles login/register flows
- Social auth (Google, Apple)
- Loading states per auth method
- Error message handling

**UserViewModel**
- User profile management
- Tried perfumes CRUD
- Wishlist CRUD
- Data synchronization

**OlfactiveProfileViewModel**
- Profile CRUD operations
- Test result processing
- Profile recommendations

**PerfumeViewModel**
- Perfume data loading
- Search and filtering
- Caching

---

## 🎯 Coding Conventions & Guidelines

### Swift Style
- Use **Swift 6.2** features
- Prefer `struct` over `class` for models
- Use `async/await` for asynchronous operations
- Leverage `Combine` for reactive streams where appropriate

### SwiftUI Best Practices
- Extract complex views into separate components
- Use `@EnvironmentObject` for shared state
- Prefer `@StateObject` over `@ObservedObject` for ownership
- Use `.task` for async initialization
- Minimize `@State` usage in child views

### Naming Conventions
- **Services:** `XxxService` (protocol: `XxxServiceProtocol`)
- **ViewModels:** `XxxViewModel`
- **Views:** Descriptive names ending in `View`
- **Models:** Noun names (e.g., `Perfume`, `User`)
- **Enums:** Singular names with lowercase raw values

### Firebase Conventions
- Collection names: lowercase, plural (e.g., `users`, `perfumes`)
- Use `FieldValue.serverTimestamp()` for timestamps
- Enable offline persistence for Firestore
- Handle auth state asynchronously

### Error Handling
- Custom `AuthServiceError` enum for auth errors
- Map Firebase errors to user-friendly messages
- Use `do-catch` blocks with typed error handling
- Always provide user feedback for errors

### Code Organization
- One model/view/service per file
- Group related files in folders
- Keep views under 300 lines (extract subviews)
- Services should be stateless (except caching)

---

## 🚀 App Launch Flow

1. **PerfBetaApp.init()**
   - Configure Firebase (if not already configured)
   - Initialize DependencyContainer
   - Create ViewModels with service injection

2. **ContentView**
   - Check `authViewModel.isAuthenticated`
   - Route to `LoginView` or `MainTabView`

3. **MainTabView (if authenticated)**
   - Show loading screen
   - Load initial data (brands, perfumes, families, notes, questions)
   - Display tab interface

4. **Tab Navigation**
   - 0: HomeTabView
   - 1: ExploreTabView
   - 2: TestOlfativoTabView
   - 3: FragranceLibraryTabView
   - 4: SettingsView

---

## 🔄 Data Flow Example: Adding a Tried Perfume

1. User navigates to Library Tab → "Add Tried Perfume"
2. `AddPerfumeOnboardingView` → Select perfume
3. `AddPerfumeStep2View` → Rate & review
4. Submit → `UserViewModel.addTriedPerfume()`
5. `UserService.addTriedPerfumeRecord()`
6. Firestore: Create document in `tried_perfumes/{userId}/records/{recordId}`
7. Update local state → UI updates automatically

---

## 🧪 Testing Notes

- **Previews:** Most views use `MockData.swift` for SwiftUI previews
- **Testing:** Currently no unit tests (opportunity for improvement)
- **Manual Testing:** Use iOS Simulator or physical device

---

## 🎨 Localization

- **Primary Language:** Spanish (es)
- **Localization File:** `Localizable.xcstrings` (String Catalog)
- All user-facing strings should use localized keys

---

## 📝 Important Implementation Details

### Firebase Persistence
- Firestore persistence is **enabled** for offline support
- Cache settings: `PersistentCacheSettings()`
- Clear cache on app delegate: `clearFirestoreCache()`

### Image Caching
- Kingfisher handles all remote images
- Memory limit: 50 MB
- Disk limit: 200 MB

### Auth State Management
- `AuthViewModel` listens to Firebase auth state changes
- Auto-stops loading indicators when auth state changes
- Handles profile verification on every auth event

### Dependency Injection
- **Singleton pattern:** `DependencyContainer.shared`
- All services are **lazy** initialized
- Firestore instance shared across services

### UI/UX Notes
- Tab bar appearance: Transparent background
- Accent color: Gold
- Loading screens show during data initialization
- Navigation uses `NavigationStack` (iOS 16+)

---

## 🎓 Learning & Development Tips

### When Adding New Features
1. Create model in `Models/` (if needed)
2. Define service protocol in `Services/`
3. Implement service with Firestore integration
4. Create ViewModel with `@Published` properties
5. Build SwiftUI views
6. Inject ViewModel via `@EnvironmentObject` or `@StateObject`

### When Modifying Views
- Always check if view is using EnvironmentObjects
- Update ViewModel, not the view directly (MVVM)
- Use `@State` for local view state only
- Extract reusable components to `Components/`

### When Working with Firebase
- Test authentication flows thoroughly (email, Google, Apple)
- Handle offline scenarios (Firestore persistence)
- Check Firestore Security Rules in Firebase Console
- Monitor quotas and usage

### Common Patterns
- **Loading states:** `@Published var isLoading = false`
- **Error handling:** `@Published var errorMessage: String?`
- **Data fetching:** Use `async/await` in ViewModels
- **UI updates:** ViewModels publish, Views observe

---

## ⚠️ Known Issues / TODOs

See `TODO.md` for comprehensive task list.

---

## 📞 Support & Resources

- **Firebase Console:** [https://console.firebase.google.com](https://console.firebase.google.com)
- **Project ID:** `perfbeta`
- **Bundle ID:** `com.testjr.perfBeta`

---

## 🔒 Security Notes

- **GoogleService-Info.plist** contains API keys (should be in .gitignore if public repo)
- Firebase security rules should restrict user data access
- Auth tokens handled by Firebase SDK
- Apple Sign-In uses secure nonce generation with CryptoKit

---

## 📚 Additional Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Kingfisher Documentation](https://github.com/onevcat/Kingfisher)

---

**Last Updated:** October 2025
**Documentation Generated by:** Claude Code Analysis
