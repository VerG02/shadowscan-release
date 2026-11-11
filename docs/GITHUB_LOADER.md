# GitHub Loader — ShadowScan v0.6.1

## Execute

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/VerG02/shadowscan-release/release-v0.6.1/loader.lua"))()
```

The loader fetches the version-pinned artifact at `dist/ShadowScan_v0.6.1_Standalone.lua` and verifies its SHA-256 before calling `loadstring`.

## Pinned configuration

- Repository: `VerG02/shadowscan-release`
- Release ref: `release-v0.6.1`
- Artifact path: `dist/ShadowScan_v0.6.1_Standalone.lua`
- Artifact SHA-256: `da46c8fd2e305a877b58f26519eeb46ed0fbecc7cbd959cd30d6fe98f8174c7b`

## Integrity model

The embedded digest detects artifact corruption or substitution relative to this loader. It does not authenticate the publisher of the loader itself. Verify `loader.lua` through the repository or an independently trusted copy. The version branch is intended to be stable; if the artifact is changed, its SHA-256 and loader must be updated together.

## Duplicate execution

The loader stores the returned ShadowScan API under a versioned key in the executor/global environment when writable. Re-executing the loader returns the active instance rather than creating another GUI. After `ShadowScan.destroy()`, the guard is cleared. If the environment disallows global writes, duplicate prevention is best-effort and the limitation must be disclosed.

## Manual fallback

If the executor does not expose a request-style HTTP function after the loader is fetched, the loader also attempts `game:HttpGet`. If neither is available, execute the standalone artifact manually from the repository.
