# ADR 0002 — Unified workspace areas

Date: 2026-11-17. Status: implemented in v0.0.1 Build 6.

## Context

The previous layout tree managed only text editors. The manuscript sidebar and information panel lived outside it, so sidebar Join could not operate on the area under the pointer. Repeated toolbar changes did not resolve that structural mismatch.

## Decision

- Represent manuscript, editor and information areas with the same pane model and split tree.
- Keep direct four-direction window controls and direct right/down controls in each area.
- Route local commands through the area's explicit ID. Use one source-expands-toward-neighbour rule for every Join.
- Render physical frames as a stable list of pane IDs. Keep AppKit text view identity when a surviving area's parent changes.
- Request keyboard focus explicitly after programmatic layout actions. Mouse activation alone must not steal focus from a title or search field.
- Migrate previous editor-only layouts into the new preference namespace without rewriting the manuscript package.

## Limits

Only complete-edge rectangular neighbours can join. Partial-edge absorption, detached editor windows and Blender's full docking engine are outside v0.0.1. Closing a view does not delete its document.
