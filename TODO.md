# TODO List - PerfBeta

**Last Updated:** December 2024
**Status:** Post Cache System & ExploreTab Optimization

---

## 🎯 High Priority

### Performance & Optimization
- [ ] Monitor cache size growth over time (add cache size limits if needed)
- [ ] Add cache clearing option in Settings for users
- [ ] Implement background app refresh for metadata sync
- [ ] Test app performance with 10,000+ perfumes in cache

### Bug Fixes & Polish
- [ ] Remove iOS 17 deprecation warnings (onChange callbacks)
- [ ] Test incremental sync thoroughly with modified perfumes
- [ ] Verify cache invalidation works correctly after Firestore updates
- [ ] Test offline functionality with airplane mode

### ExploreTab Improvements
- [ ] Consider removing debug logging in production builds
- [ ] Add analytics tracking for filter usage patterns
- [ ] Optimize filter UI for iPad (larger screens)
- [ ] Add "Recently Viewed" section in ExploreTab

---

## 📊 Medium Priority

### User Experience
- [ ] Add pull-to-refresh in ExploreTab to force metadata sync
- [ ] Show cache status indicator (last sync time) in Settings
- [ ] Add loading skeleton screens for better perceived performance
- [ ] Implement haptic feedback for filter selections

### Data & Content
- [ ] Verify all 5,587 perfumes have correct family/subfamily mappings
- [ ] Add missing perfume images (some may be null)
- [ ] Validate data consistency across all collections
- [ ] Add more educational "Did You Know?" content

### Testing
- [ ] Write unit tests for CacheManager
- [ ] Write unit tests for MetadataIndexManager
- [ ] Add integration tests for incremental sync
- [ ] Test with poor network conditions

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

### Minor Issues
- ⚠️ Xcode Breakpoints file keeps getting modified (can be gitignored)
- ⚠️ onChange deprecation warnings (iOS 17+ requires new syntax)
- ⚠️ Debug images in DesignAudit folder not gitignored

### Not Issues (By Design)
- ✅ First launch takes ~2s to download metadata (expected, one-time cost)
- ✅ ExploreTab shows empty state when no filters applied (by design)
- ✅ Debug logging is verbose (intentional for troubleshooting, remove in production)

---

## 📝 Documentation Tasks

- [ ] Update README.md with cache system overview
- [ ] Create migration guide for other developers
- [ ] Document Firestore security rules requirements
- [ ] Add inline code documentation for CacheManager
- [ ] Create architecture diagrams for cache flow

---

## 🚀 Deployment Checklist

Before pushing to production:
- [ ] Remove all debug print statements
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

- [ ] Refactor large view files (ExploreTabView is 600+ lines)
- [ ] Extract filter logic into separate FilterViewModel
- [ ] Create reusable filter components
- [ ] Consolidate duplicate code in Library views
- [ ] Consider SwiftUI ViewModifiers for repeated styling

---

## 📞 Questions / Decisions Needed

- Should we implement automatic cache size management?
- Do we need server-side validation for filter queries?
- Should debug logging be controlled by a build flag?
- Is 50 perfumes per page the optimal pagination size?
- Should we cache individual perfume detail views?

---

**Notes:**
- All cache-related commits are in git history (30 commits ahead of base)
- ExploreTab family filter fix is committed (displayName → key mapping)
- Debug logging can be disabled by commenting out print statements
- System is production-ready but would benefit from items in High Priority section
