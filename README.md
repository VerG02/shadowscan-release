# ShadowScan 0.6.2 — Standalone Runtime Intelligence

**One Luau script. Runtime inventory first, optional static source analysis.**

ShadowScan inventories the client-visible Roblox DataModel, discovers RemoteEvent / RemoteFunction / UnreliableRemoteEvent objects, classifies them, and reports evidence-first review candidates. The optional static analyzer only reads Luau source text supplied by the user. It never executes that source.

## What's new in 0.6.2

- A **minimize button** collapses the full window into a compact top-bar chip. Press **Open** to restore it.
- A **close button (×)** tears down the window and its Heartbeat connection. Re-run the loader to start another session.
- Minimize / restore transitions and button hover states use short TweenService easing when available; otherwise the interface falls back to immediate updates.
- Runtime severity counters now normalize the engine's lowercase labels (`low`, `informational`) so Dashboard and plaintext report totals agree.
- Repeated report headings are de-duplicated, and the report explains that severity and candidate priority are separate dimensions.

## Detection coverage

| Runtime (primary) | Static (optional) |
|---|---|
| RemoteEvent discovery | 19 pattern rules |
| RemoteFunction discovery | 4 correlation rules |
| UnreliableRemoteEvent discovery | Comment-aware matching |
| 14 classification families | Line-number evidence |
| 3-dimensional risk scoring | Severity + confidence |
| Factual relationship summary | Dual-mode plaintext report |
| Passive live observation | Independent evidence model |
| Session snapshots + comparison | |

## Quick start

### GitHub loader

Execute this in a Roblox executor that supports `http_request`/`request`, `loadstring`, and the relevant Roblox GUI APIs:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/VerG02/shadowscan-release/release-v0.6.2/loader.lua"))()
```

The loader fetches the pinned release artifact and verifies its SHA-256 before execution.

### Direct file

Run `dist/ShadowScan_v0.6.2_Standalone.lua` directly in the executor. The GUI appears automatically only when a supported PlayerGui/CoreGui parent is available.

### Window controls

- **–** minimizes the window to a compact bar; **Open** restores it.
- **×** closes the UI, disconnects its heartbeat lifecycle, and stops passive observation. Execute the loader again to reopen a fresh session.
- Hover and minimize/restore transitions animate when TweenService is available. Animation is optional and never required for the scanner to work.

## Build and validate

```powershell
python tools/build_standalone.py
python tools/build_standalone.py --check
python -m pytest -q
python tools/run_luau_tests.py
python tools/mutation_check.py
```

The checked-in Luau suite requires the standalone Luau CLI. Roblox executor behaviour must still be verified in the target executor; mock/CLI results do not certify executor compatibility.

## Honest limitations

The inventory is client-visible only. Replication and StreamingEnabled may hide objects. Names and metadata are hints, not proof of vulnerabilities. Server-side validation is not visible from the client. The scanner never fires remotes or changes game state. See [docs/LIMITATIONS.md](docs/LIMITATIONS.md).