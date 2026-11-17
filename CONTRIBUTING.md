# Contributing

Read [AGENTS.md](AGENTS.md), the [architecture](docs/architecture/ARCHITECTURE.md) and the [design system](docs/design/DESIGN_SYSTEM.md) before changing a module.

1. Create a feature or fix branch from `main`.
2. Keep domain, file-format, workspace and platform-UI changes in their respective modules.
3. Run `make qa` on macOS. Include the commands and results in the pull request.
4. Include screenshots for visual changes. Screenshots remain candidates until reviewed.

Preserve author text, document IDs and file-format compatibility. Layout actions must not delete manuscripts. Use synthetic documents in tests and reports; keep personal writing and local build products out of Git.

The v0.0.1 scope is native macOS writing. Propose file-format, synchronization and platform changes before implementing them.
