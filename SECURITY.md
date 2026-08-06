# Security

Please report security issues privately through the repository owner's GitHub
profile rather than opening a public issue with sensitive data.

The bridge is fail-open for Codex: write or parsing failures exit without
blocking a task. Files are created with user-only permissions, written to a
temporary file, then atomically renamed. Sequence updates use a local lock.
Events are bounded and rotated. The plugin performs no network requests and
does not modify Codex configuration or bypass Hook trust.
