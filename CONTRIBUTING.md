# Contributing to ComicArc

Pull requests are welcome. Read this before opening one.

---

## Core Rules

**No download or acquisition features.** Do not add functionality that downloads, scrapes, or fetches comic content from external sources — piracy sites, torrent networks, subscription services, or any third-party content source. PRs of this kind will be closed without review.

**Stay local-first.** ComicArc is a single-user, local app. Do not add multi-user support, shared libraries, remote hosting, or cloud sync. If you want that, fork the project.

**No DRM circumvention.** Do not add features that bypass, strip, or interact with any Digital Rights Management system.

---

## Setup

```bash
git clone https://github.com/Vivekmurugulla2004/ComicArc.git
cd ComicArc
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

**CBR support (optional):** `brew install unar` (macOS), `sudo apt install unar` (Linux).

To build the macOS .app bundle: `pyinstaller build/ComicArc.spec`

---

## Making Changes

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test manually — open the app, import a comic, read pages, create a run, verify nothing is broken. There is no automated test suite; manual testing is the bar.
5. Commit with a clear message
6. Open a pull request against `main`

For major changes, open an issue first to discuss what you'd like to change.

---

## What's Welcome

- Bug fixes
- UI improvements
- New reading modes or keyboard shortcuts
- Better mobile support
- Metadata improvements (local only — no external API scraping without discussion)
- Performance improvements
- Accessibility improvements

---

## What's Not Welcome

- Any feature for acquiring content from external sources
- Multi-user, server, or cloud features
- DRM-related functionality of any kind
- Breaking changes to the database schema without a migration

---

## Code Style

- Python: follow the existing style (no strict linter enforced)
- JavaScript: vanilla JS only, no framework dependencies
- CSS: add to `static/css/style.css`, no preprocessors
- Keep it simple — this is a personal tool, not enterprise software
