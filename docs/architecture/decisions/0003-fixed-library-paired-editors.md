# ADR 0003 — Fixed library and paired editors

Date: 2026-11-17. Status: implemented on the reference-library development branch.

## Decision

The library remains outside the editor layout. One primary editor can have one auxiliary editor, positioned left, right, above or below. The window toolbar owns direction changes; an editor header owns document selection, and only the auxiliary editor has a close control.

Moving the auxiliary editor preserves both pane IDs, document IDs and active selection. Document information uses a native sheet. Text editing, saving, reference metadata and file formats use the existing services.

## Compatibility

A new local preference namespace stores the paired-editor snapshot. Legacy area and editor-only snapshots remain readable. Migration retains the first text editor and the other active editor when present; extra views are collapsed without deleting any project document. Old preference keys remain unchanged.

The legacy split tree and its tests remain for migration and geometry compatibility, not as a second exposed UI. No document-format change is required by this layout revision.

## Verification

Test repeated direction changes, independent document selection, auxiliary close and layout undo, focus, invalid preferences, legacy keys, minimum window sizes and file round trips. Capture native UI candidates separately from automated tests; visual approval remains manual.
