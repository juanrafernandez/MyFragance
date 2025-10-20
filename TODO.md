# PerfBeta - TODO & Roadmap

## ✅ Completed Features

### Core Infrastructure
- [x] Firebase integration (Auth, Firestore)
- [x] MVVM architecture with protocol-oriented services
- [x] Dependency injection container
- [x] App state management
- [x] Kingfisher image caching
- [x] Offline Firestore persistence
- [x] Spanish localization (Localizable.xcstrings)

### Authentication
- [x] Email/password registration
- [x] Email/password login
- [x] Google Sign-In integration
- [x] Apple Sign-In integration
- [x] Auth state management with listeners
- [x] Profile creation/verification flow
- [x] Distinction between login and registration for social auth
- [x] Comprehensive error handling and user feedback
- [x] Sign out functionality

### Olfactive Profile System
- [x] Interactive questionnaire with visual elements
- [x] Profile generation based on test results
- [x] Multiple profiles per user
- [x] Gift mode (create profiles for others)
- [x] Profile management (view, edit, delete)
- [x] Profile recommendations with match percentages
- [x] Save profile after test completion

### Perfume Library (Mi Colección)
- [x] Tried perfumes list view
- [x] Wishlist view
- [x] Add perfume wizard (multi-step flow)
- [x] Custom reviews with ratings
- [x] Impressions editor
- [x] Occasions, seasons, personalities tagging
- [x] Personal projection/duration/price assessments
- [x] Library tab with sections

### Home & Discovery
- [x] Personalized home feed
- [x] Perfume carousels (horizontal lists)
- [x] Profile cards on home screen
- [x] "Did You Know?" section
- [x] All perfumes view (grid)
- [x] Greeting section

### Explore & Filter
- [x] Explore tab view
- [x] Advanced filter interface
- [x] Multi-criteria filtering (gender, family, intensity, etc.)
- [x] Filterable perfume items

### Perfume Details
- [x] Detailed perfume view
- [x] Notes pyramid display (top, heart, base)
- [x] Brand and perfumist information
- [x] Characteristics display
- [x] Add to tried/wishlist actions

### UI/UX Components
- [x] Custom gradient backgrounds
- [x] Custom slider component (ItsukiSlider)
- [x] Accordion view
- [x] Custom button styles
- [x] Color system with brand colors
- [x] Image assets for all categories
- [x] Login/SignUp UI with curved header

### Settings
- [x] Settings view
- [x] Account management
- [x] Sign out option

---

## 🚧 In Progress / Partially Implemented

### Share Functionality
- [~] Share perfume details (folder exists but implementation unclear)
- [ ] Share fragrance library
- [ ] Export collection as PDF/image

### Explore Tab
- [~] ExploreTabView exists but may need content enhancements
- [ ] Search functionality
- [ ] Advanced search with autocomplete

---

## 📋 Pending Features & Improvements

### High Priority

#### Testing & Quality Assurance
- [ ] **Unit tests** for ViewModels
- [ ] **Unit tests** for Services
- [ ] **UI tests** for critical flows (login, test, add perfume)
- [ ] **Integration tests** for Firebase operations
- [ ] Code coverage measurement

#### Performance Optimization
- [ ] Optimize Firestore queries (add indexes where needed)
- [ ] Implement pagination for perfume lists
- [ ] Reduce memory footprint (check for retain cycles)
- [ ] Profile app launch time
- [ ] Optimize image loading (lazy loading in lists)

#### User Experience Enhancements
- [ ] **Onboarding flow** for first-time users
- [ ] Tutorial/help screens for complex features
- [ ] Empty state designs (no perfumes in library, etc.)
- [ ] Loading skeletons instead of spinners
- [ ] Pull-to-refresh on list views
- [ ] Haptic feedback on key interactions
- [ ] Better error recovery (retry buttons)

#### Search & Discovery
- [ ] **Global search** across all perfumes
- [ ] Search by notes (top, heart, base)
- [ ] Search by brand
- [ ] Search by perfumist
- [ ] Recently viewed perfumes
- [ ] Trending/popular perfumes section
- [ ] "Similar perfumes" recommendations

#### Perfume Library Enhancements
- [ ] **Edit tried perfume records** (currently can only add)
- [ ] Delete individual tried perfumes
- [ ] Reorder wishlist items
- [ ] Filter library (by rating, occasion, etc.)
- [ ] Sort library (date added, rating, price, etc.)
- [ ] Statistics view (most tried families, average ratings, etc.)
- [ ] Export library as CSV/JSON

#### Social Features
- [ ] User profiles (public/private)
- [ ] Follow other users
- [ ] Share profiles with friends
- [ ] Community reviews and ratings
- [ ] Like/comment on reviews
- [ ] Perfume discussion forums

#### Notifications
- [ ] Push notifications setup
- [ ] Remind users to review perfumes
- [ ] New perfume arrivals matching profile
- [ ] Price drop alerts for wishlist items
- [ ] Friend activity notifications

#### Settings & Preferences
- [ ] Dark mode support
- [ ] Language selection (English, etc.)
- [ ] Notification preferences
- [ ] Privacy settings (profile visibility)
- [ ] Data export (GDPR compliance)
- [ ] Delete account option
- [ ] Theme customization

### Medium Priority

#### Profile System Enhancements
- [ ] Edit olfactive profiles after creation
- [ ] Retake test to update profile
- [ ] Profile comparison (side-by-side)
- [ ] Profile evolution over time (history)
- [ ] Share profile results on social media

#### Perfume Detail Improvements
- [ ] User-generated photos
- [ ] Price tracking and history
- [ ] Where to buy links (affiliate?)
- [ ] Similar perfumes section
- [ ] Perfume comparison tool
- [ ] Notes education (tap note to learn more)
- [ ] Community rating vs. personal rating

#### Recommendations
- [ ] AI/ML-powered recommendations
- [ ] Collaborative filtering (users with similar tastes)
- [ ] Recommendation explanation (why this perfume?)
- [ ] Daily perfume suggestion notification
- [ ] Seasonal recommendations

#### Analytics & Insights
- [ ] User behavior analytics (Firebase Analytics)
- [ ] Crash reporting (Firebase Crashlytics)
- [ ] Performance monitoring
- [ ] A/B testing framework
- [ ] Conversion funnel analysis

#### Monetization (Future)
- [ ] Premium features (advanced stats, unlimited profiles)
- [ ] Affiliate links to purchase perfumes
- [ ] In-app purchases
- [ ] Ads (optional, non-intrusive)

### Low Priority

#### Advanced Features
- [ ] AR try-on (visualize bottle)
- [ ] Voice search
- [ ] Barcode scanner (add perfume by scanning bottle)
- [ ] Integration with smart home (suggest perfume by weather)
- [ ] Apple Watch app
- [ ] iPad optimization
- [ ] macOS app (Mac Catalyst)
- [ ] Widgets (iOS home screen)

#### Content & Education
- [ ] Perfume education articles
- [ ] Video tutorials
- [ ] Perfume history and stories
- [ ] Perfumist interviews
- [ ] Fragrance families explainer

#### Backend & Admin
- [ ] Admin dashboard (web)
- [ ] Content management system
- [ ] User moderation tools
- [ ] Analytics dashboard
- [ ] A/B test management

---

## 🐛 Known Issues & Bugs

### Critical
- [ ] Verify auth state persistence after app restart
- [ ] Test offline mode thoroughly (Firestore cache)
- [ ] Handle network errors gracefully

### Medium
- [ ] Memory leaks check (especially in views with @EnvironmentObject)
- [ ] Large image handling (very high-res images might crash)
- [ ] Tab bar animation glitches on some iOS versions

### Low
- [ ] UI inconsistencies across different screen sizes
- [ ] Localization strings missing for some new features
- [ ] Loading indicators might not stop in edge cases

---

## 🔧 Technical Debt

### Code Quality
- [ ] Refactor large ViewModels (split responsibilities)
- [ ] Extract magic strings to constants
- [ ] Add documentation comments to complex functions
- [ ] Standardize error handling patterns
- [ ] Remove unused code and assets
- [ ] Implement proper logging (OSLog or third-party)

### Architecture
- [ ] Consider Coordinator pattern for navigation
- [ ] Implement Repository pattern for data layer
- [ ] Abstract Firestore dependencies (easier to test/mock)
- [ ] Add Use Cases layer between ViewModels and Services

### Security
- [ ] Add Firestore Security Rules review
- [ ] Implement proper keychain storage for sensitive data
- [ ] SSL pinning for API calls (if using custom backend)
- [ ] Code obfuscation for release builds
- [ ] Add .gitignore for GoogleService-Info.plist (if public repo)

### Build & Deployment
- [ ] Set up CI/CD pipeline (GitHub Actions, Fastlane)
- [ ] Automate screenshot generation for App Store
- [ ] Set up beta testing with TestFlight
- [ ] Configure different environments (dev, staging, prod)
- [ ] Automate versioning and changelog generation

---

## 🎯 Milestones & Roadmap

### Version 1.0 (MVP - Current Status: ~90%)
**Target: Ready for Beta Testing**
- [x] Core authentication
- [x] Olfactive profile test
- [x] Perfume library (tried & wishlist)
- [x] Basic home feed
- [x] Perfume details
- [x] Basic filtering
- [ ] Polish UI/UX
- [ ] Fix critical bugs
- [ ] Add onboarding

### Version 1.1 (Post-Launch Improvements)
**Target: 1-2 months after launch**
- [ ] Edit tried perfume records
- [ ] Global search
- [ ] Statistics view
- [ ] Performance optimizations
- [ ] Unit tests coverage (50%+)
- [ ] Dark mode

### Version 1.2 (Social Features)
**Target: 3-4 months after launch**
- [ ] User profiles
- [ ] Follow system
- [ ] Community reviews
- [ ] Share functionality (complete)
- [ ] Notifications

### Version 2.0 (Advanced Features)
**Target: 6-12 months after launch**
- [ ] AI recommendations
- [ ] Monetization (premium features)
- [ ] AR try-on
- [ ] Apple Watch app
- [ ] Content hub (articles, videos)

---

## 📊 Prioritization Matrix

### Must Have (Do First)
1. Fix critical bugs
2. Add onboarding flow
3. Implement edit/delete for tried perfumes
4. Global search
5. Unit tests for core features
6. Empty states and error handling

### Should Have (Do Soon)
1. Dark mode
2. Performance optimizations
3. Statistics view
4. Advanced filtering
5. Profile editing
6. Push notifications

### Nice to Have (Do Later)
1. Social features
2. Community reviews
3. AR try-on
4. Apple Watch app
5. Monetization features

---

## 🧪 Testing Checklist

### Manual Testing (Pre-Release)
- [ ] Test all auth flows (email, Google, Apple)
- [ ] Test offline mode (airplane mode)
- [ ] Test on different iOS versions (17.2, 18.x)
- [ ] Test on different devices (iPhone SE, standard, Max)
- [ ] Test iPad layout (if supported)
- [ ] Test accessibility (VoiceOver, Dynamic Type)
- [ ] Test localization (Spanish)
- [ ] Test edge cases (empty lists, long text, special characters)
- [ ] Test memory usage with large datasets
- [ ] Test battery drain

### Automated Testing (Future)
- [ ] Set up XCTest framework
- [ ] Write ViewModel tests
- [ ] Write Service tests (with mocks)
- [ ] Write UI tests for critical flows
- [ ] Set up test coverage reporting
- [ ] Integrate tests into CI/CD

---

## 📚 Documentation Needs

- [x] CLAUDE.md (project overview for AI assistant)
- [x] TODO.md (this file)
- [ ] README.md (for developers)
- [ ] CONTRIBUTING.md (contribution guidelines)
- [ ] API.md (if using custom backend)
- [ ] CHANGELOG.md (version history)
- [ ] User guide (in-app or external)
- [ ] Privacy policy
- [ ] Terms of service

---

## 🚀 Deployment Checklist

### Pre-Launch
- [ ] App icon finalized (all sizes)
- [ ] Launch screen finalized
- [ ] App Store assets prepared (screenshots, description, keywords)
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Firebase project configured for production
- [ ] Firestore security rules reviewed
- [ ] App Store Connect account set up
- [ ] Beta testing completed (TestFlight)
- [ ] App Store review guidelines compliance check

### Post-Launch
- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Track key metrics (DAU, retention, conversion)
- [ ] Plan for first update based on feedback
- [ ] Marketing and social media presence

---

## 💡 Ideas for Future Exploration

- **Gamification:** Badges, achievements, levels
- **AI Chat Bot:** Ask questions about perfumes
- **Subscription Box Integration:** Suggest perfume samples
- **Events:** Virtual perfume launch events
- **Marketplace:** Buy/sell/trade perfume samples
- **Fragrance Diary:** Daily mood + perfume tracker
- **Weather Integration:** Suggest perfume based on weather
- **Calendar Integration:** Suggest perfume for calendar events
- **Travel Mode:** Suggest perfumes for destinations
- **Blind Testing:** Rate perfumes without knowing the brand

---

**Last Updated:** October 2025
**Project Status:** Beta-ready (MVP ~90% complete)
**Next Sprint Focus:** Bug fixes, onboarding, edit features
