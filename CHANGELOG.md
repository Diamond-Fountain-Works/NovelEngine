# Changelog

## Unreleased — 0.0.1 development

- Add a managed bookshelf and project home with author credits, genre, status, original cover and unrestricted synopsis.
- Automatically save to the system Documents folder with serialized snapshots, conflict checks and truthful save states.
- Add `.ne` import/export, retain legacy `.novelengine` import, and introduce Format 3 project metadata.
- Isolate native QA with a separate bundle ID and a required test-library root.

- Add manuscript, character, event, worldbuilding and setting sections in the vertical library rail.
- Add typed reference cards, subdocuments, canon status, tags and document links.
- Store event participants, prerequisites and story-time anchors separately from display codes.
- Read Formats 1 and 2; keep chapter/note-only projects compatible with Format 1.
- Keep reference editing in the existing workspace and preserve text through explicit UTF-8 edits.
- Avoid unchanged metadata writes and isolate property input in a native sheet.
- Replace repeated area controls with a fixed library and paired editors; direction buttons reposition the auxiliary editor.
- Select each editor's document independently and migrate legacy layout preferences without changing project files.


## 0.0.1 — 2026-11-17

- Native macOS document app with chapters, notes, synopses, search and ordering.
- Unified workspace areas for the manuscript browser, text editor and chapter information.
- Direct four-way splitting, adjacent-area joining, area-type switching and layout undo.
- Keyboard focus follows programmatic area creation, joining and document opening.
- UTF-8 text and JSON metadata in versioned `.novelengine` document packages.
- Diamond Fountain Works light and dark themes, typography settings and focus mode.
- Swift package tests, publication checks and macOS CI.

Source release. The macOS development bundle is version 0.0.1, Build 6.
