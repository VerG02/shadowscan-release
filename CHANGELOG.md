# Changelog

## 0.6.1 — Final packaging and reliability adjustments

* Configured the production loader for `VerG02/shadowscan-release`, pinned to `release-v0.6.1`,
  with the exact `dist/ShadowScan_v0.6.1_Standalone.lua` path and a mandatory embedded SHA-256.
* Added a duplicate-execution guard using the executor/global environment where writable. The loader
  returns the active instance on repeat execution and clears its guard when the application is destroyed.
* Added a `game:HttpGet` fallback after request-style HTTP functions, while retaining fail-closed
  response validation and artifact hash verification.
* Partial/cancelled scans no longer mark unvisited inventory entries as stale. Absence is inferred
  only from a complete inventory pass.
* Live observation now uses the same duplicate-sibling path suffixing as full inventory scans.
* Live buffer overflow now emits a one-time Heartbeat render signal while remaining available in
  report history; it no longer forces a render on every subsequent Heartbeat.
* Corrected README console API examples and added loader/package invariant tests.

## 0.6.1 — Critical Stabilization & Repair
Mandatory repair release after an independent source audit of the 0.6.0 ZIP. No new features: the
existing architecture is preserved and the defects below are fixed. Every claim in this entry is
backed by a test listed in docs/TEST_RESULTS.md.

### P0 — application bootstrap
* **The standalone artifact now INSTANTIATES the application.** The 0.6.0 tail imported `src.main`
  as a module and returned a wrapper over the uninitialized class table: `describe()` crashed
  (`util.describe_caps(nil)`), `report_text(source, name)` forwarded its arguments into the
  combined-report method (wrong signature), and no UI could ever open despite `open_ui()` claiming
  it "opens automatically in an executor". The 0.6.1 tail detects the real Roblox `game`
  environment, resolves a supported GUI parent (executor hidden-UI hook, then LocalPlayer PlayerGui,
  then CoreGui), constructs a `ScreenGui` with the real `Instance.new` factory, detects the viewport
  from the current camera, and instantiates `main.new(opts)`. Headless environments construct the
  instance without a GUI and every console call still works.
* **Lifecycle:** a `RunService.Heartbeat` connection drains passive live observation and re-renders
  on change; the connection, the ScreenGui and the instance are torn down by `ShadowScan.destroy()`
  (and by the ScreenGui's Destroying signal). Headless startup prints `not constructed (console
  mode)` — the tool never claims a GUI opened when it did not.
* **Console API corrected:** `report_text(source, name)` now produces the STATIC report for that
  source (0.6.0 silently dropped the static findings); `report_text()` with no arguments returns the
  combined runtime report; `describe()` is pcall-guarded and can no longer crash a loader that only
  inspects the result; `open_ui()` returns the app or an honest reason.
* **Executor capability probing** covers `getgenv`/`getfenv`/`_G` candidate environments.

### P1 — scan responsiveness
* **Safe cooperative yielding replaces the empty callback.** The session resolves `task.wait` (or
  legacy `wait`) at construction and wraps it in a pcall so a sandboxed/broken wait can never abort
  a scan; yield failures are counted and disclosed (`yields_missed`). Large scans release the
  execution thread between batches.
* **Performance profiles are actually applied.** LOW IMPACT / BALANCED / FAST now drive
  `batch_budget_ms`, `batch_min`, `batch_max` and `progress_every` of every scan (0.6.0 hardcoded
  the balanced numbers and ignored `PROFILE_SETTINGS`); the applied settings are exposed on
  `session.last_scan_settings` and mutation-checked.
* **Cancellation exists and is wired into the UI.** While a scan runs, the top-bar button becomes a
  Cancel control; the session stops at the next batch boundary and the status is CANCELLED (or
  PARTIAL at the object cap) with the partial observations, findings and report kept.
* **Progress is meaningful:** the visited count renders into the top bar between batches (possible
  because the scan yields cooperatively).

### P1 — passive live observation
* **Bounded drain lifecycle:** discoveries enter the PERSISTENT inventory (0.6.0 merged into a dead
  `scan_result` table and crashed on `stats.by_class` being nil), findings AND graph are re-derived,
  duplicates are suppressed against existing observations, and the drain runs on the heartbeat.
* **Overflow is explicitly reported** (session log + `last_live_overflow`), never silently dropped.
* **`live.reset()`** clears dedupe memory and counters on session reset, so objects seen before a
  reset can be re-discovered afterwards.

### P1 — inventory identity and stale records
* **Name-based paths are no longer assumed unique.** Same-name siblings under one parent receive
  deterministic `[2]`..`[n]` suffixes (first occurrence keeps the plain path), so distinct objects
  stay distinct records; a `disambiguated` counter is exposed in the scan stats.
* **Stale objects are explicit:** records not observed in the latest scan are marked
  `stale`/`stale_since`, disclosed in the snapshot header (`Stale: N`) and the Explorer inspector,
  and never silently reported as current. `first_seen`/`last_seen` are preserved across scans.

### P1 — snapshot comparison
* **`session:compare(previous, latest)` compares two actual snapshots** (explicit previous/latest
  selection in the Session page; 0.6.0 called a method that did not exist, so the button errored).
* **Save Latest saves the intended snapshot:** the most recent STORED snapshot is persisted
  (0.6.0 silently captured a brand-new one).
* **Legacy v1/v2 snapshot lines parse completely.** 0.6.0's legacy branch was unreachable (nested
  inside the four-field pattern that can never match a three-field line) and its malformed records
  crashed comparisons on a nil path.
* **No more double counting:** renamed/reparented matches (medium confidence, labels preserved) are
  consumed from plain ADDED/REMOVED; the speculative same-class "POSSIBLY_MOVED" pairing (low
  confidence) was removed — plain adds/removes are reported honestly instead of being guessed into
  moves. Metadata equality is now part of rename/reparent matching.

### P1 — GitHub loader
* **Placeholder configuration is fatal:** unconfigured REPO_OWNER, REPO_NAME, or a
  missing/malformed (non-64-hex) EXPECTED_SHA256 aborts before any network activity. There is no
  mode that skips integrity verification (0.6.0 printed a warning and ran an unverified artifact).
* **HTTP success is verified where available** (`Success == false` and non-200 `StatusCode` are
  rejected); invalid response shapes, short bodies and marker-less bodies are rejected.
* **The digest actually works.** 0.6.0's SHA-256 used bitwise operators that are not valid Luau
  syntax in the standard toolchain AND mis-indexed the message schedule (`w[i + 1]`, leaving `w[64]`
  unassigned) — the integrity check could never have run. 0.6.1 inlines the proven bit32-based
  `src/sha256.lua` implementation verbatim and verifies it against FIPS 180-4 test vectors.
* **Artifact integrity vs publisher authentication are clearly distinguished** (header comment and
  failure messages). The release stays pinned to `v0.6.1`. Result inspection is pcall-guarded: a
  broken `describe()` in the artifact can never abort the loader.

### P2 — UI controls and graph
* **Fixed the nil-first arrays in the Explorer and Findings filters:** `{ nil, "RemoteEvent", ... }`
  made `ipairs` stop at index 1, so NOT A SINGLE filter button rendered in 0.6.0. Filters now carry
  `{label, value}` entries and actually filter the rows.
* **Fixed two crash-on-empty states:** the Findings page crashed when the filtered list was empty
  and the Graph page crashed before any scan (`children[#children + 1] = panel(...)` grows `#children`,
  so the follow-up assignment indexed the next, nil, slot).
* **Added the missing `accent_soft` theme token** (selecting a row in the Explorer crashed rendering
  on an invalid hex color in 0.6.0).
* **Graph page renamed to what it renders:** a bounded container summary (CHILD_OF counts); it does
  not draw a node/edge visualization, and the page now says so.

### QA
* 40 new Luau tests (26 regression + 14 loader) and 2 new pytest tests; all 43 Luau + 8 pytest tests
  from 0.6.0 are preserved and pass (83 Luau + 10 pytest total, 13/13 mutations caught, build
  deterministic). The Luau suite now runs against the real console bootstrap instead of the bare
  module set.
* **Real Roblox/executor behaviour remains UNVERIFIED** and is documented as such: no GUI opening,
  clipboard, filesystem or HTTP capability has been tested outside the Luau CLI and the mock
  environment. See docs/LIMITATIONS.md.

## 0.6.0 — Standalone Runtime Intelligence Edition
Combines the runtime remote intelligence from 0.4.x with the static source analyzer from 0.5.0 into one self-contained Luau script.

* **Restored runtime intelligence (from 0.4.2):** bounded passive inventory scan (RemoteEvent/RemoteFunction/UnreliableRemoteEvent), 14-family classification with provenance, evidence-first analyzer, three-dimensional risk scoring (priority/confidence/status), factual relationship graph (bounded), passive live observation (bounded buffer), session snapshots + comparison with disclosed confidence levels, performance profiles.
* **Preserved static analyzer (from 0.5.0):** 19 detection rules + 4 correlations, comment-aware matching, line-number evidence, bounded processing.
* **Dual-mode report:** plaintext, origin-labeled (RUNTIME vs STATIC), with evidence/explanation/impact/recommendation per finding, inventory summary, environment section, relationship summary, session snapshot, final assessment, limitations.
* **New 8-page UI:** Dashboard, Remote Explorer (search/filter/sort/inspector/copy), Findings (filters/sorting/origin labels), Graph (bounded container listing), Session Intelligence (snapshots + comparison + diff), Static Analyzer (paste + scan), Reports (generate/copy/export), Settings (profiles/live/reset). Top bar with scan control and live toggle. Bottom status bar with profile/object count/limitations.
* **New GitHub loader:** versioned release fetch, SHA-256 integrity verification, duplicate-execution prevention, clear error messages, clearly marked configuration placeholders.
* **Removed (staying removed from 0.5.0):** Companion, Decryptor, encryption, localhost server, pairing tokens, Python CLI, manifests/active testing, AI layer.
* All 43 Luau tests pass, 9 pytest tests pass, 6/6 mutation defects caught.

## 0.5.0 — Standalone Edition
A deliberate product narrowing: one self-contained Luau script, zero external dependencies.

* **Removed (intentional, with their tests):** Companion app (`desktop/`, `companion/`), Decryptor app,
  age encryption pipeline (`encryption/`), encrypted report generation, localhost server, pairing tokens,
  Python CLI (`shadowscan.py`), manifest/active-testing (`test_manifest/`, `scanner/active_runner.lua`),
  the object-scanner GUI pages, performance profiles, AI layer (`ai/`), capability-report page, and the
  loader/bundle distribution machinery (`loader/`, `dist/shadowscan.bundle.lua`, `RELEASE.json`). No
  unused modules, dead configuration or placeholder components remain.
* **New: standalone source analyzer** (`standalone/`): 19 detection rules + 4 correlation rules over
  user-provided Luau source, comment-aware matching, bounded scanning (line/evidence/findings caps,
  cooperative yields, PARTIAL marking), severity classification (CRITICAL/HIGH/MEDIUM/LOW/INFORMATIONAL),
  overall risk assessment, plaintext report (evidence, explanation, potential impact, recommendation per
  finding), clipboard + TXT export with capability detection and manual-copy fallbacks, single-page UI
  (Dashboard / Source Input / Analysis / Results / Export) with diff-based rendering.
* **New deliverable:** `ShadowScan_v0.5.0_Standalone.lua` — one file, no runtime dependencies, built
  deterministically by `tools/build_standalone.py`; headless console API (`ShadowScan.report_text`)
  identical to the UI path.
* **New tests:** 42 Luau behavioral tests (rules, engine, report/export, app) + 9 pytest build/static
  tests incl. a headless deliverable probe, + a 6-defect mutation check (all caught).
* **Baseline:** 0.4.2 (the workspace's latest release; the brief references a 0.4.3 baseline that does not
  exist in this repository). Baseline results before the refactor: 285 pytest + 130 Luau, all green —
  recorded in git history of this workspace and in the 0.4.2 archive.
* The analysis never executes the inspected source, never touches the network, and never reads scripts the
  user did not provide. Static analysis cannot prove runtime behaviour; the report says so in every audit.

## 0.4.2 - release verification final hardening
* **Fixed (P0/P1): `release-verify --policy required` no longer accepts a self-signed release.** Previously a
  validly self-signed release without a trusted-keys file printed NOT AUTHENTICATED but exited 0. The required
  policy now REQUIRES a non-empty trusted public-key set: a missing trusted-keys file fails, an empty file
  fails, and a signature from an unknown key fails - even when the signature is internally consistent.
* **Fixed (P0/P1): a signed RELEASE.json with an empty files map was accepted.** The file manifest is now
  strictly validated: exactly `loader.lua` and `shadowscan.bundle.lua`; empty maps, missing artifacts,
  unexpected entries, absolute/nested/traversal paths, malformed sha256 (length/charset), negative or invalid
  byte counts, and actual hash/size mismatches are all rejected. Metadata is checked BEFORE any filesystem
  access; untrusted filenames never reach a path join before the allowlist.
* 17-case CLI regression matrix (`tests/test_release_verify.py`) covering the full spec table - each case
  asserts output text AND exit code.
* **P2: Ed25519 signing requires the `cryptography` backend.** The pure-Python fallback (not side-channel
  hardened) now refuses to sign with `SigningBackendError`; verification keeps the strict fallback with
  identical semantics. RFC vectors, forgery rejection and small-order rejection preserved.
* Docs: RELEASE/MANIFEST/LIMITATIONS/ENCRYPTION updated - internal consistency vs authenticated releases,
  why the trusted key must be independent, why `--policy required` demands a trusted key, which exact files
  are verified, why hashes alone establish no publisher identity, why loader verification is out-of-band.
* Unchanged: all 0.4.1 fixes and features, all security gates, age encryption, report formats.

## 0.4.1 - cryptographic hardening & performance patch
* **P0 - Ed25519 verification hardened.** The pure-Python verifier accepted small-order public keys, and a
  reproducible forgery with the identity key (`01` + 31 zero bytes) verified for arbitrary messages. The new
  implementation enforces strict semantics on every backend: scalar canonicality (< L), canonical point
  encodings (decode+re-encode round trip), and rejection of ALL small-order (8-torsion) keys and R points
  (identity, order-2/4/8; exact [8]Q == identity test). The maintained `cryptography` package is the preferred
  backend (requirements.txt); a hardened pure-Python fallback keeps identical semantics (tested by forcing it).
  RFC 8032 vectors preserved; 10 new regression tests incl. the exact identity-key forgery that previously passed.
  Manifest and release signature FORMATS are unchanged - no migration needed; old signatures remain valid.
* **P1 - release signature trust.** `release-verify` no longer treats the embedded public key as trust: a
  self-signed release is reported as "internally consistent but NOT AUTHENTICATED". New `--trusted-keys`
  (out-of-band key file, inline `#` comments supported) and `--policy required` authenticate a release only
  when the signing key is trusted. File-hash tampering still fails regardless of signatures. The 0.4.1
  release itself is UNSIGNED (no maintainer key available in the build environment) - documented.
* **P1 - manifest signing workflow documented** (docs/MANIFEST.md): sign on PC -> validate with
  `--policy required --trusted-keys` -> verify hash -> distribute -> executor runs its structural gates.
  Explicit disclosure: the executor does NOT verify signatures.
* **P1 - scanner time-budget hardening.** The elapsed budget is checked INSIDE the batch loop (every 16 items,
  before popping, so no item can ever be dropped - a bug the new mixed fan-out regression test caught during
  development); very large child lists are pushed in resumable 256-record slices with identical DFS order;
  cancellation stays responsive during fan-out (regression-tested). Benchmarks added: fan-out 10k/50k,
  5,000-deep chain, cancellation during 50k fan-out (docs/BENCHMARK.md). One Roblox API call cannot be
  interrupted mid-call - documented.
* **P2 - AI settings persistence.** AI preferences are a real persisted Settings field (provider/models/URLs
  only); `Settings.save`/`load` sanitize secret-named keys, so an API key can never reach disk (regression tests).
* **P2 - external AI transport security.** External endpoints REQUIRE HTTPS; plain HTTP only for explicitly
  local endpoints; malformed URLs, embedded credentials, query strings and unknown schemes are rejected at
  construction; errors never contain keys (tests).
* Fixed during release: the trusted-keys file parser ignored inline comments (keys with `# label` never matched).
* Unchanged: every 0.4.0 feature, the 0.3.0 features, all security gates, age encryption, report formats,
  encrypted TXT export, no plaintext fallback.

## 0.4.0
* **Runtime compatibility layer (`client/compat.lua`).** Every optional environment capability is probed explicitly with statuses (supported / unsupported / partial / not_tested / failed_init); the report appears on the GUI Settings page, in the console and in every report (`environment.compatibility`). Degradations are loud, never silent substitutions. New executor-only functions (`delfile`, `toclipboard`) are detected, never assumed. A documented runtime acceptance test plan exists in `docs/COMPATIBILITY.md`; real executor compatibility remains NOT TESTED.
* **Performance profiles.** LOW IMPACT / BALANCED / FAST presets (batch budget 1.5/3/6 ms with matching batch bounds) selectable from the GUI Settings page and recorded in reports (`environment.performance_profile`). Benchmark matrix (3 profiles x 5 sizes, 100..20,000 objects) with per-batch percentiles: all profiles complete a 20k scan in ~35 ms on the dev desktop; LOW IMPACT mean batch 0.22 ms (p95 0.83 ms), BALANCED 0.84 ms (p95 1.45 ms), FAST 1.7 ms (p95 2.63 ms); memory identical and bounded (~2.7 MB). Full table: `docs/BENCHMARK.md`.
* **Sharper intelligence.** Classification families extended to the 0.4.0 set (Economy, Currency, Shop, Inventory, Rewards, Progression, Combat, Movement, Teleportation, Admin, Permission, Trading, Social, Unknown) with provenance on every match. Risk is now THREE separate scores: candidate priority (0-100), evidence confidence (low/medium/high from the evidence kind), and verification status (unverified/.../confirmed from the verdict) - a high priority is explicitly not a confirmation. 0.3.0 reports stay valid (new fields optional).
* **Optional AI layer with real providers (`ai/`).** Modular providers: deterministic (offline rules, clearly labelled as rules), Ollama (local model, localhost by default), OpenAI-compatible (user-configured; per-call confirmation enforced in code). Disabled by default; works offline without it. Only redacted metadata leaves the process; every answer is wrapped in grounding labels (OBSERVED DATA / DETERMINISTIC RULE RESULT / AI HYPOTHESIS / VERIFIED TEST RESULT / UNKNOWN INFORMATION). New AI Analyst page in the Companion (API key stays in the window, never saved to disk).
* **Session intelligence.** Snapshots v2 (per-remote metadata + family fingerprints), richer diffs: added / removed / metadata-changed (match confidence high) / moved (name-based, match confidence low), plus the honest note that disappearance is not deletion (replication/streaming). Snapshot deletion via `delfile` when the executor offers it, refused loudly otherwise. New Session Compare and Graph pages in the GUI.
* **Release integrity.** Optional Ed25519-signed RELEASE.json (`tools/build.py --sign-key`, `python shadowscan.py release-verify` verifies file hashes + signature; tampering fails both). Manifest validation gained a signature policy: `--policy required` rejects unsigned manifests, `--trusted-keys` rejects unknown signing keys.
* Unchanged: all 0.3.0 features, the 0.2.1 fixes, the allowlist/expiry/plan-hash gates, no plaintext fallback, age encryption (no custom crypto), encrypted TXT export format.

## 0.3.0
* **Advanced Remote Intelligence Explorer (new GUI page).** Smart classification buckets remotes into functional families (admin, economy, inventory, transport, ...) from name/parent tokens; every classification carries its basis and is a hint, never a fact (confidence is capped at medium). Risk scoring gives each candidate a transparent 0-100 score with a per-factor breakdown; weak-only evidence is capped into the low band, mirroring the severity cap. The relationship graph derives factual structure (child_of / sibling_of / co_named) with bounded output; the Explorer pages through it lazily.
* **Audit Session Snapshot and Comparison.** Save a compact remote-surface fingerprint (`ShadowScan/out/snapshot-*.json`), compare later: added/removed remotes, place-mismatch refusal, and the diff rides in the report (`summary.snapshot_diff`).
* **Passive Live Observation.** Optional, event-driven watcher (DescendantAdded) records newly replicated objects of interest into the current audit; bounded buffer, dedupe, player-character skip, honest "unavailable" when the environment lacks the signal. Analysis is re-derived only when events arrive - never per frame.
* **Incremental, adaptive scanner.** `inventory.scan` now processes objects in wall-clock-budgeted batches (default ~3 ms, configurable `batch_budget_ms`) with an adaptive batch size and one yield between batches. Benchmark: 19,620 mock objects in ~30 ms total, mean 0.73 ms/batch, max 1.76 ms, retained Lua memory ~2.6 MB after GC (`tools/benchmark.py`, `tests/test_benchmark.py`, `docs/PERFORMANCE.md`).
* **Approved Test Plan Generator.** Produces a manifest DRAFT from the highest-risk remote candidates. The draft is deliberately INVALID until a human replaces the DRAFT/REPLACE approval placeholders - both validators (Luau + Python) reject unedited drafts (parity-tested).
* **Optional Ed25519 manifest signatures (PC-side).** Pure-Python RFC 8032 implementation (tested against the RFC vectors); `python shadowscan.py keygen-ed25519` + `manifest-sign`. The companion/CLI verify; the Luau client cannot verify Ed25519 and treats the block as shape-checked metadata - documented trust model. Signatures protect authenticity of a public document; reports stay age-encrypted (no custom crypto anywhere).
* **Optional Local Analyst in the Companion.** Offline heuristic hypotheses (untested high-band candidates, economy clusters, admin surface without negative-input coverage, rate-limit questions, positive-only coverage, secret-shaped replication) - off by default, runs on the PC after validation, never sends anything, never upgrades a verdict.
* **Report schema 1.1.** Optional `classification`/`risk` on findings, `relationships` summary, `summary.snapshot_diff`, `analyst`. Schema 1.0 reports remain valid (validator accepts both; documented migration).
* Unchanged: allowlist, manifest expiry, hash-pinned loader, plan-bound confirmation, no plaintext fallback, age interoperability, the 0.2.1 fixes.

## 0.2.1
* **Fixed: RightShift GUI toggle (Issue A).** The default loader path (no injected `UserInputService`) now falls back to `game:GetService("UserInputService")`; the key is only claimed when a service was actually bound. The sidebar hint says so honestly ("reopen from the console: ui:show()") when no binding exists. All input connections are tracked and disconnected on `destroy()`. 8 new Luau regression tests (`tests/luau/test_ui_toggle.lua`).
* **Fixed: pairing token exposure in the Companion (Issue B).** The executor command preview now always shows the `YOUR_ONE_TIME_TOKEN` placeholder; a deliberate **Copy Command** action constructs the full line with the real token. The token cannot appear in any readable widget (the no-secrets UI test now walks every unmasked widget, which is exactly how the old leak slipped through).
* **Export format (Issue C).** The encrypted report exports as `ShadowScan_Audit_YYYYMMDD_HHMMSS.txt` (age-armored ciphertext, UTC name) with a `.sha256` sidecar (`<hash>  <file name>`), plus a new **Save Metadata** action (file name/hash/size/timestamps/audit id - no report content) and **Clear Session** on the Secure Export page. The Scanner page gains **Refresh Inventory** (re-derives candidates from memory, sends nothing) and **Clear Current Session**.
* **Windows compatibility (Issue D).** The full suite and both desktop apps now run **on Windows**: fixed path separators in the static-invariant tests, cross-platform stand-in fonts for the layout previews (Verdana/Consolas on Windows, chosen wide so overflow checks stay conservative), desktop UI tests run on the real display when Xvfb is unavailable, screenshots composed from the real window grab, per-monitor DPI awareness (best effort), a Windows-legal long-path test fixture, and honest platform reporting in `docs/TEST_RESULTS.md`.
* Docs: new `docs/INSTALL_WINDOWS.md`, `docs/ENCRYPTION.md`, `docs/REPORT_FORMAT.md` (replaces `REPORT.md`).
* Unchanged: allowlist, manifest expiry, hash-pinned loader, plan-bound confirmation, no plaintext fallback, age interoperability.

## 0.2.0
* **Roblox GUI** (6 pages) built from a tested declarative scene; layout rules enforced by code on every page and window size.
* **Companion app** (Tkinter): session, recipients/key creation, reports, settings. **Decryptor app**: step flow, checksum honesty, passphrase-protected keys, preview, explicit save.
* Shared design tokens (`design/tokens.json`), 4px grid, WCAG-checked contrast (`accent_fill` for filled buttons).
* Encrypted TXT export: companion returns ASCII-armored age ciphertext + SHA-256 on request (`X-ShadowScan-Return: ciphertext`); the client verifies the hash. Armor verified against the official `age` 1.2.1 in both directions.
* Passphrase-protected key files (age scrypt); distinct errors for wrong key vs altered data.
* Cancellable scan; reports from cancelled scans are marked `aborted` / `scan_cancelled` and "PARTIAL" (schema: optional `summary.scan_cancelled`).
* Companion: event hooks (metadata only), Stop button support, quick restart on POSIX without weakening Windows port exclusivity.
* Companion can be restarted right after Stop on Linux/macOS (SO_REUSEADDR); Windows keeps exclusive port binding.
* Fixed: the decryptor classified every decryption failure as "wrong key"; now only a real no-match is, tampering is reported as damaged/altered.
* Unchanged: allowlist, manifest expiry, hash-pinned loader, plan-bound confirmation, no plaintext fallback.

## 0.1.0
First release: passive recon, analyzer, allowlisted active tests, encrypted reports, loopback companion, tests.
