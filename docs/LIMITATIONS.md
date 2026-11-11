# Honest limitations (0.6.1)

## Runtime limitations
* The inventory is **client-visible only** — StreamingEnabled and replication can hide objects.
* A disappearance between snapshots does not prove deletion. Renamed/reparented snapshot matches are
  name-based (medium confidence, disclosed per row); unmatched additions/removals are reported
  plainly and never guessed into "moves".
* Names, metadata and structure are hints. Server-side validation is invisible from the client.
* The scanner never fires remotes, never modifies game state, never reads server-only instances.
* One expensive Roblox API call (e.g. `GetChildren` on a huge parent) cannot be interrupted mid-call.
* **Inventory identity paths disambiguate same-name siblings with `[2]`..`[n]` suffixes based on
  child enumeration order.** The order is stable within a session but Roblox does not formally
  guarantee a stable child order across server hops — a renamed-between-scans object may surface as
  remove+add rather than a tracked identity.

## Static analysis limitations
* Comment lines are skipped — patterns mentioned only in comments do not raise findings.
* Encoded or runtime-assembled content is visible only as an indicator; decoded values are not analyzed.
* The engine never executes the analyzed source.
* Source must be provided by the user — the tool does not extract scripts.

## Executor compatibility
* **UNVERIFIED — including the GUI.** The tool was tested in the standalone Luau CLI and a mock
  environment only. In a real executor the UI construction path (PlayerGui / CoreGui hook /
  `Instance.new("ScreenGui")`) and the `RunService.Heartbeat` lifecycle have NOT been exercised;
  the deliverable prints what actually happened (`constructed (<parent>)` or `not constructed
  (console mode)`) instead of claiming success. Do not assume the UI opens until you have run it in
  your target executor and seen the window.
* Clipboard, filesystem, HTTP and GUI capabilities differ per executor. Each is probed at runtime
  with graceful fallbacks — never a faked success.
* No GUI protection or anti-detection techniques are used.

## Loader
* The embedded SHA-256 proves **artifact integrity only** (the downloaded bytes match the release
  the loader was built for). It does NOT authenticate the publisher of the loader itself — verify
  this file through an out-of-band channel (compare its own hash) before trusting it.
* Unconfigured repository fields or a missing/malformed expected hash abort the loader before any
  network activity. There is no mode that skips integrity verification.
* The loader never executes the analyzed content of a scan; it executes ONLY the release artifact
  after its digest matches. If the check fails, do not run anything by hand either.

## Performance
* Batch budget numbers are engineering targets measured in the Luau CLI, not Roblox frame-time
  guarantees. LOW IMPACT / BALANCED / FAST change the batch budget/size and progress cadence of
  every scan (verified by tests); they do not change what is scanned.
* Large inventories degrade into PARTIAL reports with explicit reasons; a cancelled scan produces a
  CANCELLED report with the partial results kept.
* Live observation depends on `DescendantAdded` support; buffer overflow is reported explicitly.

## Removed in 0.5.0 (intentional)
Companion, Decryptor, encryption, localhost server, pairing tokens, Python CLI, manifests/active testing, AI layer. See CHANGELOG for the full list.
* Names, metadata and structure are hints. Server-side validation is invisible from the client.
* The scanner never fires remotes, never modifies game state, never reads server-only instances.
* One expensive Roblox API call (e.g. `GetChildren` on a huge parent) cannot be interrupted mid-call.

## Static analysis limitations
* Comment lines are skipped — patterns mentioned only in comments do not raise findings.
* Encoded or runtime-assembled content is visible only as an indicator; decoded values are not analyzed.
* The engine never executes the analyzed source.
* Source must be provided by the user — the tool does not extract scripts.

## Executor compatibility
* **UNVERIFIED.** The tool was tested in the standalone Luau CLI and a mock environment only.
* Clipboard, filesystem, HTTP and GUI capabilities differ per executor. Each is probed at runtime with graceful fallbacks — never a faked success.
* No GUI protection or anti-detection techniques are used.

## Performance
* Batch budget numbers are engineering targets measured in the Luau CLI, not Roblox frame-time guarantees.
* Large inventories degrade into PARTIAL reports with explicit reasons.
* Live observation depends on `DescendantAdded` support.

## Removed in 0.5.0 (intentional)
Companion, Decryptor, encryption, localhost server, pairing tokens, Python CLI, manifests/active testing, AI layer. See CHANGELOG for the full list.
