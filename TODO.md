# TODO List - PerfBeta

**Last Updated:** November 2025
**Status:** Production Ready - Final Polish Phase

---

## Current Sprint

### High Priority
- [ ] Test on physical devices (iPhone 12, 13, 14, 15)
- [ ] Test on different iOS versions (17.2, 17.6, 18.0+)
- [ ] Verify Firebase quotas are sufficient for production
- [ ] Final UI/UX polish pass

### Medium Priority
- [ ] Add pull-to-refresh in ExploreTab to force metadata sync
- [ ] Add loading skeleton screens for better perceived performance
- [ ] Add cache status indicators in Settings (size, last sync time)
- [ ] Test offline functionality with airplane mode

---

## Completed (November 2025)

### Architecture & Code Quality
- [x] **AppStartupService** - Centralized startup coordination
  - Created `StartupStrategy` enum with 4 startup paths
  - Created `CacheAvailability` struct for cache tracking
  - Refactored ContentView to use AppStartupService
  - Simplified UserViewModel by delegating cache detection

- [x] **UnifiedRecommendationEngine Modularization**
  - Extracted `WeightProfile.swift`
  - Extracted `RecommendationFilters.swift`
  - Extracted `RecommendationScoring.swift`
  - Extracted `ProfileCalculationHelpers.swift`

- [x] **QuestionsService Unification**
  - Migrated from separate services to unified `QuestionsService`
  - Supports all question types: olfactive, gift, opinion

- [x] **Debug Logging Protection**
  - All 485+ print statements wrapped with `#if DEBUG`
  - Production builds have no console output

- [x] **Code Cleanup**
  - Removed all migration scripts (Python, JS, Shell)
  - Removed temporary JSON data files
  - Removed obsolete documentation
  - Updated CLAUDE.md and README.md

### Cache System (December 2024)
- [x] **CacheManager** - Actor-based permanent disk cache
- [x] **MetadataIndexManager** - Lightweight perfume index
- [x] **Incremental Sync** - 99.77% reduction in Firestore reads
- [x] **Unit Tests** - 24 tests with 100% coverage

### UI/UX Improvements
- [x] **ExploreTab Refactoring** - 686 lines → 394 lines
- [x] **FilterViewModel** - Reusable filter logic
- [x] **Swipe-to-Delete** - All list views
- [x] **onChange Deprecation** - All 30 occurrences fixed

---

## Backlog

### Performance
- [ ] Monitor cache size growth over time
- [ ] Implement background app refresh for metadata sync
- [ ] Test with 10,000+ perfumes in cache
- [ ] Consider image prefetching for top perfumes

### Testing
- [ ] Integration tests for incremental sync
- [ ] Test with poor network conditions
- [ ] Add Firebase Analytics events

### Features (Future)
- [ ] "Save Search" functionality
- [ ] Search history
- [ ] Compare Perfumes feature
- [ ] Voice search
- [ ] Dark mode optimization

### Accessibility
- [ ] VoiceOver support testing
- [ ] Dynamic Type improvements
- [ ] Color blindness testing

---

## Technical Debt

### Low Priority
- [ ] Create reusable filter components (further abstraction)
- [ ] Consider SwiftUI ViewModifiers for repeated styling
- [ ] Architecture diagrams for cache flow

---

## Deployment Checklist

Before App Store release:
- [x] Fix onChange deprecation warnings
- [x] Add #if DEBUG flags for all logging
- [x] Centralize startup logic (AppStartupService)
- [ ] Test on physical devices
- [ ] Test clean install flow
- [ ] Test upgrade flow (existing users)
- [ ] Update app version and build number
- [ ] Verify all API keys are in .gitignore
- [ ] Perform security audit
- [ ] App Store screenshots and metadata

---

## Architecture Overview

```
App Startup Flow:
1. PerfBetaApp → ContentView
2. ContentView → AppStartupService.determineStrategy()
3. Strategy determines UI state:
   - freshInstall → Loading screen → Download all
   - fullCache → MainTabView immediately → Background sync
   - partialCache → Load cache → Download missing
4. MainTabView ready

Key Services:
- AppStartupService (Startup coordination)
- CacheManager (Disk persistence)
- MetadataIndexManager (Perfume index)
- QuestionsService (All question types)
- UnifiedRecommendationEngine (Recommendations)
```

---

**Notes:**
- System is production-ready
- All critical refactoring complete
- Focus now on testing and polish
