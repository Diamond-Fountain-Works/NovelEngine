# Novel Engine

**A native writing workspace for long-form fiction.**

[简体中文](README.zh-CN.md) · [Documentation](docs/README.md) · [Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md)

[![macOS CI](https://github.com/Diamond-Fountain-Works/NovelEngine/actions/workflows/ci.yml/badge.svg)](https://github.com/Diamond-Fountain-Works/NovelEngine/actions/workflows/ci.yml)
![Version](https://img.shields.io/badge/version-0.0.1-blue)
![macOS](https://img.shields.io/badge/macOS-13%2B-black)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Novel Engine brings chapters, notes and manuscript editing into a configurable native macOS workspace. Split areas in any direction, keep reference notes beside your draft, and save your work as readable local files.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/workspace-dark.png">
  <img src="docs/assets/workspace-light.png" alt="Novel Engine manuscript browser and native editor" width="1100">
</picture>

## Features

- **Manuscripts and notes.** Create chapters and notes, edit synopses, search titles, reorder documents, and see character and paragraph counts.
- **Area-based workspace.** Split left, right, up or down with direct buttons. Switch an area's content between the manuscript browser, editor and chapter information. Join adjacent areas and undo layout changes independently of text edits.
- **Native text editing.** SwiftUI with an AppKit text editor, input-method composition, selection, copy and paste, and text undo and redo.
- **Readable local documents.** A `.novelengine` package contains JSON metadata and separate UTF-8 text files. File Format 1 preserves document IDs and original text.
- **Two appearances.** Diamond Fountain Works light and dark themes, typography controls, and a focus view that preserves the workspace layout.

## Getting started

Requirements: macOS 13 or later and a Swift 6 toolchain. Development and UI checks currently run on Apple Silicon.

```sh
git clone https://github.com/Diamond-Fountain-Works/NovelEngine.git
cd NovelEngine
make run
```

The command builds and opens `build/Novel Engine.app`. To work in Xcode, open [`apps/apple/macOS/Package.swift`](apps/apple/macOS/Package.swift) and choose the `NovelEngine` product.

The native interface currently uses Simplified Chinese. v0.0.1 is a macOS source release; additional platform clients and cross-device synchronization are tracked in the [roadmap](docs/roadmap/PHASES.md).

## Workspace controls

| Action | Control |
| --- | --- |
| Split the active area | Four direction buttons in the window toolbar |
| Split a specific area | Its direct right/down buttons or header context menu |
| Change area content | Type selector at the left of the area header |
| Join adjacent areas | Right-click the area header or shared divider; the source area expands in the chosen direction |
| Undo a layout change / restore default layout | Layout menu in the window toolbar |
| New chapter / note | ⇧⌘N / ⌥⌘N |
| Save / settings | ⌘S / ⌘, |

Joining and closing areas change views, not manuscript files. v0.0.1 joins rectangular neighbours that share a complete edge.

## Development

```sh
make build   # Build the macOS development app
make test    # Domain, layout, AppKit and document-package tests
make check   # Documentation, module boundaries and publication checks
make qa      # Build, tests and checks
```

| Directory | Responsibility |
| --- | --- |
| `apps/apple/macOS` | App scene, document adapter and bundle configuration |
| `packages/novel-core-swift` | Domain models, editing operations, file codec and workspace geometry |
| `packages/novel-ui-apple` | SwiftUI views, design tokens and AppKit adapters |
| `protocol` | Platform-neutral document-format specification |
| `docs` | Product, architecture, design, development and QA records |
| `script` / `scripts` | Build entry point and repository checks |

See the [architecture](docs/architecture/ARCHITECTURE.md), [file format](protocol/PROJECT_FORMAT.md) and [QA record](docs/qa/NATIVE_QA.md) for implementation details and tested scope.

## License

[MIT](LICENSE) · © 2026 [Diamond Fountain Works](https://github.com/Diamond-Fountain-Works).
Bundled fonts and reference-preview icons retain the licenses listed in [Third-party notices](THIRD_PARTY_NOTICES.md).
