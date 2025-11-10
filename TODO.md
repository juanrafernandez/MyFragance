# TODO List - PerfBeta

**Last Updated:** January 2025
**Status:** Post Cache System & Feature Development

---

## 🎯 High Priority

### Critical Bug Fixes
- [x] ~~**FIX: Remove iOS 17 onChange deprecation warnings**~~ ✅ **DONE** (30 occurrences in 14 files fixed)
  - Commit: 423c509 "fix: update onChange modifiers to iOS 17+ syntax across 10 views"
  - All files updated to iOS 17+ compliant syntax

### Performance & Optimization
- [ ] Monitor cache size growth over time (add cache size limits if needed)
- [x] ~~Add cache clearing option in Settings for users~~ ✅ **DONE** (SettingsView.swift:37-54)
- [ ] **Add cache status indicators in Settings** (size, last sync time)
- [ ] Implement background app refresh for metadata sync
- [ ] Test app performance with 10,000+ perfumes in cache

### Code Quality & Refactoring
- [ ] **Refactor ExploreTabView** (currently 671 lines, exceeds recommended 300)
  - Extract: ExploreTabSearchSection
  - Extract: ExploreTabFilterSection
  - Extract: ExploreTabResultsSection
- [x] ~~**Implement build flag system for debug logging**~~ ✅ **DONE** (485 print statements wrapped)
  - Commits: 90b0dbd, f914194, 9669cd5
  - All debug logging now excluded from production builds
- [ ] Test incremental sync thoroughly with modified perfumes
- [ ] Verify cache invalidation works correctly after Firestore updates

---

## 📊 Medium Priority

### User Experience
- [ ] Add pull-to-refresh in ExploreTab to force metadata sync
- [x] ~~Show cache status indicator (last sync time) in Settings~~ ⚠️ **PARTIAL** (clearing works, display missing)
- [ ] Add loading skeleton screens for better perceived performance
- [ ] Implement haptic feedback for filter selections
- [ ] Test offline functionality with airplane mode
- [ ] Add analytics tracking for filter usage patterns

### Data & Content
- [ ] Verify all 5,587 perfumes have correct family/subfamily mappings
- [ ] Add missing perfume images (some may be null)
- [ ] Validate data consistency across all collections
- [ ] Add more educational "Did You Know?" content

### Testing
- [ ] **Write unit tests for CacheManager** (PerfBetaTests.swift is empty template)
- [ ] **Write unit tests for MetadataIndexManager** (no test file exists)
- [ ] Add integration tests for incremental sync
- [ ] Test with poor network conditions
- [ ] Test on physical devices (iPhone 12, 13, 14, 15)
- [ ] Test on different iOS versions (17.2, 17.6, 18.0+)

---

## 🔮 Low Priority / Future Enhancements

### Features
- [ ] Add "Save Search" functionality in ExploreTab
- [ ] Implement search history
- [ ] Add voice search for perfumes
- [ ] Create "Compare Perfumes" feature (side-by-side comparison)

### Analytics & Monitoring
- [ ] Add Firebase Analytics events for:
  - Cache hit/miss rates
  - Filter usage patterns
  - Search queries
  - Most viewed perfumes
- [ ] Add Crashlytics for better error tracking
- [ ] Monitor Firestore read patterns in production

### Performance
- [ ] Consider implementing image prefetching for top perfumes
- [ ] Optimize PerfumeCard rendering for large lists
- [ ] Add virtual scrolling for very long lists (1000+ items)
- [ ] Investigate SwiftData for future cache implementation (iOS 17+)

### Accessibility
- [ ] Add VoiceOver support testing
- [ ] Improve Dynamic Type support
- [ ] Add accessibility labels to all interactive elements
- [ ] Test with color blindness simulators

---

## 🐛 Known Issues

### Critical Issues
- [x] ~~**onChange deprecation warnings**~~ ✅ **FIXED** - All 30 occurrences updated to iOS 17+ syntax
- [x] ~~**Debug logging in production**~~ ✅ **FIXED** - All 485 print statements wrapped with #if DEBUG flags

### Minor Issues
- ⚠️ Xcode Breakpoints file keeps getting modified (can be gitignored)
- ⚠️ Debug images in DesignAudit folder not gitignored
- ⚠️ ExploreTabView exceeds 600 lines (currently 671 lines)

### Not Issues (By Design)
- ✅ First launch takes ~2s to download metadata (expected, one-time cost)
- ✅ ExploreTab shows empty state when no filters applied (by design)
- ✅ Debug logging is verbose (intentional for troubleshooting, should be flagged for production)

---

## 📝 Documentation Tasks

- [ ] **Update README.md with cache system overview** (currently only brief mentions)
- [ ] Create migration guide for other developers
- [ ] Document Firestore security rules requirements
- [x] ~~Add inline code documentation for CacheManager~~ ✅ **DONE** (comprehensive comments exist)
- [x] ~~Add inline code documentation for MetadataIndexManager~~ ✅ **DONE** (comprehensive comments exist)
- [ ] Create architecture diagrams for cache flow

---

## 🚀 Deployment Checklist

Before pushing to production:
- [x] ~~**FIX: Remove onChange deprecation warnings (30 occurrences)**~~ ✅ **DONE**
- [x] ~~**Remove all debug print statements or add #if DEBUG flags (485 occurrences)**~~ ✅ **DONE**
- [ ] Test on physical devices (iPhone 12, 13, 14, 15)
- [ ] Test on different iOS versions (17.2, 17.6, 18.0+)
- [ ] Verify Firebase quotas are sufficient
- [ ] Update app version and build number
- [ ] Test clean install flow (no cache)
- [ ] Test upgrade flow (existing users with old cache)
- [ ] Verify all API keys are in .gitignore
- [ ] Run SwiftLint and fix warnings
- [ ] Perform security audit

---

## 💡 Ideas for Future Sprints

### Sprint 3 Ideas
- Perfume recommendations based on weather API
- Social features (share perfumes with friends)
- AR try-on using device camera
- Seasonal perfume collections
- Gift recommendation wizard

### Sprint 4 Ideas
- Apple Watch companion app
- Siri shortcuts integration
- Widget for favorite perfumes
- Dark mode optimization
- iPad-specific layouts

---

## 🔧 Technical Debt

### Critical Refactoring
- [ ] **Refactor ExploreTabView (671 lines → extract to smaller components)**
  - Current structure makes maintenance difficult
  - Should split into: SearchSection, FilterSection, ResultsSection

### Code Improvements
- [x] ~~Extract filter logic into separate FilterViewModel~~ ✅ **DONE** (FilterViewModel.swift exists, 285 lines)
- [x] ~~Consolidate duplicate code in Library views~~ ✅ **DONE** (both use FilterViewModel)
- [ ] Add #if DEBUG preprocessor directives for all debug logging
- [ ] Create reusable filter components (further abstraction)
- [ ] Consider SwiftUI ViewModifiers for repeated styling
- [ ] Remove .gitignored files from tracking (Xcode breakpoints, DesignAudit images)

---

## 📞 Questions / Decisions Needed

- Should we implement automatic cache size management?
- Do we need server-side validation for filter queries?
- Should debug logging be controlled by a build flag?
- Is 50 perfumes per page the optimal pagination size?
- Should we cache individual perfume detail views?

---

## ✅ Recently Completed Features

### December 2024 - Cache System & Performance
- ✅ **Infinite Cache System** - CacheManager & MetadataIndexManager implementation
- ✅ **Incremental Sync** - 99.77% reduction in Firestore reads after first launch
- ✅ **ExploreTab Optimization** - Metadata-based filtering with lazy loading
- ✅ **Family Filter Fix** - DisplayName → Key mapping for accurate filtering

### Library Features
- ✅ **Sorting System** - FilterViewModel with multiple sort orders (rating, name)
  - ✅ Removed popularity sorting from TriedPerfumes (only rating & name)
- ✅ **Swipe-to-Delete** - Implemented in TriedPerfumes, Wishlist, and Profiles
- ✅ **Loading States** - Comprehensive loading UI across all views
- ✅ **Cache Clearing** - User-facing cache management in Settings
- ✅ **Rating Icons** - Customized icons per section
  - 💜 TriedPerfumes: Heart icon for personal rating
  - ⭐ Wishlist: Star icon for perfume popularity
- ✅ **TriedPerfumes Loading Pattern** - Unified with Wishlist approach (January 2025)
  - ✅ Eliminated "Desconocido" placeholder bug
  - ✅ Simplified TriedPerfumeRowView to match WishListRowView pattern
  - ✅ Added loadMetadataIfNeeded() in FragranceLibraryTabView
  - ✅ Implemented loadMissingPerfumes() in TriedPerfumesListView
  - Commit: e14be78

### Architecture Improvements
- ✅ **FilterViewModel** - Generic, reusable filter logic (285 lines)
- ✅ **Inline Documentation** - CacheManager & MetadataIndexManager fully documented
- ✅ **Code Consolidation** - Removed duplication in Library views

---

## 🎯 Priority Summary

**Critical (Must Fix Before Production):**
1. [x] ~~Fix onChange deprecation warnings (30 occurrences)~~ ✅ **DONE**
2. [x] ~~Add #if DEBUG flags for logging (485 print statements)~~ ✅ **DONE**
3. Refactor ExploreTabView (671 lines → components)

**High Value:**
1. Add cache status indicators in Settings
2. Write unit tests (CacheManager, MetadataIndexManager)
3. Update README.md with cache system overview

**Nice to Have:**
1. Background app refresh for metadata sync
2. Pull-to-refresh in ExploreTab
3. Loading skeleton screens

---

**Notes:**
- All cache-related commits are in git history (branch: `claude/clean-up-todo-list-*`)
- ExploreTab family filter fix is committed (displayName → key mapping)
- System is production-ready **except** for deprecation warnings and debug logging
- FilterViewModel successfully reused across TriedPerfumes, Wishlist, and ExploreTab
- Last comprehensive audit: January 2025
