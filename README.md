# ShadowScan 0.4.2

Official version-pinned release artifacts for ShadowScan, a client-side Roblox/Luau security auditing toolkit.

## Release artifacts

- `dist/loader.lua` — Luau entry point and integrity verifier.
- `dist/shadowscan.bundle.lua` — bundled ShadowScan runtime.
- `dist/RELEASE.json` — release metadata and SHA-256 hashes.

## Build

Version: 0.4.2
Build ID: fbb3136e0e45

## Security

The loader verifies the bundle SHA-256 before execution.
Use immutable commit-pinned URLs, never moving branch URLs.

## Compatibility

The desktop Companion self-test has passed on Windows.
Roblox runtime and third-party executor compatibility have not yet been verified.

Use only in authorized testing environments. Third-party executors may be subject to Roblox platform restrictions.
