# ShadowScan v0.6.1 — Standalone Runtime Intelligence

One standalone Luau artifact. No companion app, backend, localhost service, or encryption.

ShadowScan passively inventories remote objects visible to the Roblox client: RemoteEvent, RemoteFunction, and UnreliableRemoteEvent. It provides evidence-based classification, priority/confidence/status assessment, passive live observation, session snapshots/comparison, and plaintext reports. Optional static analysis scans Luau source explicitly supplied or authorized by the user.

> Runtime inventory is client-visible only. It is not a complete server inventory and cannot establish server-side vulnerability from names or metadata alone. ShadowScan never fires/invokes remotes, fuzzes endpoints, reads protected script source, or executes analyzed source.

## Execute

Paste this single line into a compatible Roblox executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/VerG02/shadowscan-release/release-v0.6.1/loader.lua"))()
```

The loader fetches the version-pinned artifact, verifies its embedded SHA-256 before execution, and uses a duplicate-execution guard when the environment supports it.

## Manual fallback

The standalone artifact is at [dist/ShadowScan_v0.6.1_Standalone.lua](dist/ShadowScan_v0.6.1_Standalone.lua). Direct execution bypasses the loader's download and integrity check.

## Release integrity

- Version: 0.6.1
- Artifact: dist/ShadowScan_v0.6.1_Standalone.lua
- SHA-256: da46c8fd2e305a877b58f26519eeb46ed0fbecc7cbd959cd30d6fe98f8174c7b
- Loader: loader.lua
- Integrity verification checks the downloaded artifact against the loader's embedded digest. It does not independently authenticate the loader publisher.

See docs/LIMITATIONS.md, docs/ARCHITECTURE.md, docs/DETECTION.md, and docs/GITHUB_LOADER.md.

Real Roblox/executor compatibility must be verified in the target runtime; Luau CLI tests do not establish executor compatibility.
