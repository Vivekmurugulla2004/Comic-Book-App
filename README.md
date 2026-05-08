# ComicArc

A local comic reader for files you own. No accounts, no cloud, no subscriptions.

> Only import files you legally own or have the right to access. See [LEGAL.md](LEGAL.md).

---

## Quick Start

**macOS (one-click):** Clone the repo, then double-click `ComicArc.command`.

**Windows (one-click):** Clone the repo, then double-click `ComicArc.bat`.

**macOS / Linux:**
```bash
git clone https://github.com/Vivekmurugulla2004/ComicArc.git
cd ComicArc
./setup.sh
./run.sh
```

**Windows:**
```bat
git clone https://github.com/Vivekmurugulla2004/ComicArc.git
cd ComicArc
setup.bat
run.bat
```

Open [http://localhost:5001](http://localhost:5001). Press `Ctrl+C` to quit.

---

## Screenshots

> Coming soon — run locally and take a look.

---

## What This Is

ComicArc is a **single-user, local-first** app that runs on your own computer and serves only you. It has no accounts system, no multi-user support, no server-side storage, and no way to share files with other people. It organizes and serves comic files that live on your hard drive — it does not host, stream, or distribute content.

Think of it the same way you think about:
- **iTunes / Music** — organizes music files you own
- **Plex / Infuse** — organizes video files you own
- **Calibre** — organizes ebook files you own

ComicArc does the same thing for comic files.

---

## Features

**Library**
- Drag-and-drop or folder import for CBZ, CBR, PDF, and image files
- Grid view with cover thumbnails, reading progress, and star ratings
- Filter by publisher, tags, or search by title/series
- Favorites and Continue Reading section
- Metadata editor (title, series, publisher, issue number)

**Reader**
- Page-by-page and vertical scroll (manga) reading modes
- Double-page spread mode
- Zoom and pan
- Autoplay mode — automatically advances pages on a timer
- Keyboard shortcuts (see table below)
- Touch swipe support on mobile
- Progress saves automatically

**Narrative Runs**
- Build ordered reading lists spanning multiple series and publishers
- Drag-and-drop reordering
- Per-issue notes, ratings, and favorites
- Auto-advance between comics in a run

**Stats**
- Total comics, pages read, favorites, completion tracking
- Breakdown by publisher and top series

**Progressive Web App**
- Install to your phone or desktop home screen
- Works offline once loaded (static assets cached)

---

## Requirements

- Python 3.9+
- CBR support: `brew install unar` (macOS), `sudo apt install unar` (Linux), [7-Zip](https://www.7-zip.org/) in PATH (Windows)
- PDF support: PyMuPDF — installed automatically via `requirements.txt`

---

## Importing Comics

Drag and drop CBZ, CBR, PDF, or image files onto the import zone. Click **Import Folder** to import a whole folder at once.

To scan from a folder, organize files under `~/Downloads/Comics/Publisher/Series/` and visit `/scan`.

---

## Supported Formats

| Format | Notes |
|--------|-------|
| `.cbz` | Built-in |
| `.cbr` | Requires unar |
| `.pdf` | Requires PyMuPDF |
| `.jpg` / `.jpeg` / `.png` | Built-in |

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `←` / `→` | Previous / next page |
| `Space` | Next page |
| `A` | Toggle autoplay |
| `V` | Vertical scroll mode |
| `D` | Double-page spread |
| `Z` | Zoom |
| `F` | Fullscreen |
| `Escape` | Exit zoom / close modal / stop autoplay |

---

## Links

- **GitHub:** [github.com/Vivekmurugulla2004/ComicArc](https://github.com/Vivekmurugulla2004/ComicArc)

---

## Legal

Personal use only. Read [LEGAL.md](LEGAL.md) before using.

---

## License

MIT — see [LICENSE](LICENSE). Covers the software only, not any comic content.
