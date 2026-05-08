# Changelog

All notable changes to ComicArc are documented here.

---

## [1.0.0] — 2026-05-08

First public release.

### Desktop App
- Native macOS app bundle (.app) — no Python or terminal required
- Built with PyWebView + PyInstaller; runs entirely offline
- Native folder picker dialog for choosing library location
- All data stored in `~/Library/Application Support/ComicArc/` (DB, covers, config)
- Auto-scans library folder on every launch for newly added files

### Onboarding
- First-launch wizard: choose library folder → scan with live progress → pick reader mode
- Config persisted to `config.json` (library path, reader mode, onboarding flag)
- Reset Setup in Settings re-runs the wizard without losing library data

### Library
- Drag-and-drop and folder import for CBZ, CBR, PDF, JPG, JPEG, and PNG files
- Grid view with cover thumbnails, reading progress bars, and star ratings
- Filter by publisher tabs, tag chips, and free-text search (title/series)
- Favorites and Continue Reading section on the library home page
- Metadata editor — edit title, series, publisher, issue number, tags
- Reading list ("Want to Read") — queue comics from detail page or bulk select
- Bulk select mode — mark read/unread, add to reading list, delete multiple at once
- Manual drag-and-drop reordering (sort: Manual)
- Mark Unread button on comic detail page
- Delete comic with confirmation (removes from library; files stay on disk)

### Reader
- Page-by-page navigation with keyboard (← →, Space) and touch swipe
- Vertical scroll mode for manga-style reading
- Double-page spread mode
- Zoom and pan
- Autoplay mode — auto-advances pages every 10 seconds with countdown bar (A key)
- Fullscreen mode (F key)
- Keyboard cheat sheet modal — press `?` or click the `?` button in the toolbar to see all shortcuts
- Home / End keys jump to first and last page
- Default reader mode preference (page / scroll) saved from onboarding/settings
- Progress saves automatically on each page turn
- Auto-advance to next comic when a run is active

### Narrative Runs
- Create ordered reading lists spanning multiple series and publishers
- Add any comic from the library to any run
- Drag-and-drop reordering within a run
- Per-issue notes, star ratings, and favorites
- Auto-advance between comics at end of each issue

### Stats
- Total comics, pages read, favorites, and narrative runs count
- Completion tracking (finished vs. in-progress vs. unread)
- Breakdown by publisher with visual bar chart
- Top series by issue count
- Recently read history
- Empty state when library has no comics

### Settings
- Change library folder and trigger rescan from the app
- Switch default reader mode (page / scroll)
- CBR support: one-click "Install via Homebrew" with live install log
- CBR detection fixed for bundled .app (explicit Homebrew path fallback)
- Export full library data as JSON backup (comics, progress, ratings, tags, runs, reading list)
- Reset Setup — re-run onboarding without losing data
- Clear Library — remove all library data (files stay on disk)

### Technical
- Flask + SQLite backend wrapped in PyWebView native window
- Background scanner thread with file-signature deduplication (name + size)
- `reading_list` table with ON DELETE CASCADE foreign key
- Bulk operation API endpoints (delete, mark-read, mark-unread, reading-list)
- Export endpoint returns `Content-Disposition: attachment` JSON response
- Removed dead CSS classes and unused routes from previous terminal-based setup
- No accounts, no cloud, no external network requests
- All data stays on the user's machine
