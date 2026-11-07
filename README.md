# ShadowScan

Black-box, **client-side** security auditing for Roblox games, for testers who have **explicit permission from the game owner**.
ShadowScan complements your static *Roblox Luau Security Auditor*: that tool reads your own source code; ShadowScan only sees
what a normal player's client sees, and says so honestly in every report.

* **Passive recon** - inventories replicated objects (RemoteEvent / RemoteFunction / ProximityPrompt / ClickDetector / DragDetector ...). Sends nothing.
* **Candidate analyzer** - turns observations into *candidates* with evidence, unknowns, provisional severity, confidence and suggested tests. A remote called `GiveMoney` is a hint, never proof.
* **Active tests - allowlist only** - fires only endpoints listed in a developer-approved, expiring **test manifest**, behind a dry run, a plan-bound confirmation, call/interval/duration limits and stop conditions. No "fire everything", no payload generation, no fuzzing, no retry-until-success.
* **Verdicts you can defend** - `OBSERVED`, `CANDIDATE`, `TESTED_REJECTED`, `TESTED_ACCEPTED`, `CONFIRMED`, `INCONCLUSIVE`, `NOT_TESTED`. A RemoteEvent with no response is `INCONCLUSIVE`, never "success".
* **Reports are always encrypted** - a loopback-only Python companion validates the report, encrypts it with [age](https://age-encryption.org) for every authorised recipient, and writes **ciphertext only**. If anything fails, nothing is stored and nothing falls back to plaintext.

> **Status: 0.4.3 hotfix candidate.** This patch explicitly injects the executing script's `game` reference into the runtime session and makes the in-game GUI respect Roblox core UI safe insets. The Python/desktop and mocked Luau test coverage from 0.4.2 is preserved, but this 0.4.3 build has only been checked with build/static tests in this environment; a Luau CLI and `pyrage` are unavailable here, and no real Roblox/executor test has been run. See [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) for the verification boundary.
> See [docs/LIMITATIONS.md](docs/LIMITATIONS.md) and [docs/TEST_RESULTS.md](docs/TEST_RESULTS.md) for exactly what was and was not verified.

> **Terms of service.** Third-party executors may violate Roblox's Terms of Use even when the game owner agrees. Prefer testing in
> Roblox Studio or on a private QA place/server that the owner controls. You are responsible for staying within the owner's permission and the platform rules.

### Three front ends, one design system

| | What it is | How you open it |
|---|---|---|
| **Roblox GUI** | In-game window (Overview, Scanner, Findings, Approved Tests, Secure Export, Settings / About). Opens automatically after the loader; hide/show with **RightShift** when a `UserInputService` is available (the sidebar says honestly when it is not) | Workspace loader or commit-pinned one-paste URL mode (pass `ui = false` for the console-only API) |
| **Companion** | Windows app that receives the report on `127.0.0.1`, encrypts it for every recipient and stores only ciphertext. Manage recipients and keys without a terminal | double-click **`ShadowScan Companion.pyw`** (or `python shadowscan.py gui`) |
| **Decryptor** | Separate app for the people who READ reports: open the encrypted TXT, check its SHA-256, decrypt with your key, preview, save | double-click **`ShadowScan Decryptor.pyw`** (or `python shadowscan.py decryptor`) |

Screenshots (1366x768 and 1920x1080) are in `docs/screenshots/`. **The Roblox ones are layout previews drawn from the UI model, not Roblox screenshots**; the Tk ones are real windows (on Windows the real display; on Linux under Xvfb). Design rules and honest limits: [docs/UI.md](docs/UI.md). Everything in 0.1.0 (allowlisted active tests, manifest expiry, hash-pinned loader, no plaintext fallback) is unchanged.

**New in 0.4.0:** a **runtime capability layer** (every environment probed explicitly, honest degradation, compatibility report in the GUI and in reports), **performance profiles** (Low Impact / Balanced / Fast, measured in [docs/BENCHMARK.md](docs/BENCHMARK.md)), **sharper intelligence** (0.4.0 classification families + three separate scores: priority / evidence confidence / verification status), an **optional AI layer with real providers** (deterministic rules / local Ollama / user-configured external - grounded, redacted, confirmation-gated, off by default, [docs/AI.md](docs/AI.md)), **session comparison v2** (metadata changes, low-confidence move matching, snapshot deletion), a **Graph page** and a **Session Compare page**, and **signed releases** (optional Ed25519 RELEASE.json signatures + `release-verify`).

**New in 0.3.0:** an **Explorer** page (functional family classification + evidence-based risk scores + relationship graph - all hints, honestly labelled), **audit snapshots and comparison** (what appeared or disappeared between sessions), **passive live observation** (newly replicated objects are recorded while you play; bounded and cancellable), an **incremental ~3 ms-batch scanner** (19,620 mock objects in ~30 ms, see docs/PERFORMANCE.md), a **draft test-plan generator** (deliberately invalid until a human approves it), **optional Ed25519 manifest signatures** (PC-side) and an **optional local analyst** in the Companion (offline heuristics, off by default).

**New in 0.2.1:** the RightShift toggle works on the default loader path (with an honest fallback when `UserInputService` is unavailable); the Companion's command preview shows a `YOUR_ONE_TIME_TOKEN` placeholder and only **Copy Command** assembles the real line; the encrypted report exports as `ShadowScan_Audit_YYYYMMDD_HHMMSS.txt` (+ `.sha256` sidecar) with Save Metadata and Clear Session actions; the whole suite and both desktop apps now run on Windows. Details: [CHANGELOG.md](CHANGELOG.md).

---

## 1. Install on Windows (step by step)

Requirements: Windows 10/11, **Python 3.11 or newer** (https://www.python.org/downloads/ - tick *Add python.exe to PATH* and keep *tcl/tk and IDLE* ticked: the apps use Tkinter), PowerShell. **The full walkthrough below was executed on Windows during the 0.2.1 release** - see [docs/INSTALL_WINDOWS.md](docs/INSTALL_WINDOWS.md).

```powershell
# 1) get the repository (or unzip it) and open PowerShell inside the folder
cd C:\tools\shadowscan

# 2) create an isolated environment and install the 3 dependencies
python -m venv .venv
.\.venv\Scripts\Activate.ps1          # if blocked: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
python -m pip install -r requirements.txt

# 3) sanity check: companion + encryption end to end, no Roblox involved
python shadowscan.py selftest
#   expected: HTTP 201: True; encrypted files: 3; plaintext visible in ciphertext: False; decrypts to the original: True

# 4) build the release files (bundle + pinned loader + RELEASE.json)
python shadowscan.py build
```

### 1a. Create YOUR key pair (once per person)

```powershell
python shadowscan.py keygen --out $HOME\.shadowscan\me.key --label "tester me"
```
The private key goes to the file you name (it refuses to write inside the repo and refuses to overwrite). **It is never printed.**
Back it up somewhere safe; if you lose it, reports encrypted for you cannot be recovered. Send **only the printed `age1...` public key** to whoever needs to encrypt for you.

### 1b. Add the authorised recipients (developer, you, anyone you allow)

```powershell
python shadowscan.py recipients add age1....developer... --label "developer: studio lead"
python shadowscan.py recipients add age1....you......... --label "tester: me"
python shadowscan.py recipients list
```
Details and key rotation: [docs/RECIPIENTS.md](docs/RECIPIENTS.md).

### 1c. Put the files where your executor can read them

Copy these three files into your executor's **workspace** folder (its name and location depend on the executor), keeping the sub-folder:

```
<executor workspace>\ShadowScan\loader.lua
<executor workspace>\ShadowScan\shadowscan.bundle.lua
<executor workspace>\ShadowScan\manifest.json        (only when you run active tests)
```
Then **verify the loader's hash** against `dist\RELEASE.json` (or the release notes you received out-of-band):
```powershell
Get-FileHash dist\loader.lua -Algorithm SHA256
```
The loader itself verifies the bundle's SHA-256 and refuses to run on any mismatch. See [docs/RELEASE.md](docs/RELEASE.md).

### 1d. One-paste URL mode (commit-pinned)

After publishing the generated `dist/` artifacts to a public GitHub release repository, use the SAME 40-character commit SHA in both URLs. Replace `OWNER/REPO`, `COMMIT_SHA`, and the authorized QA PlaceId; do not use a moving branch such as `main`.

```lua
local commit = "COMMIT_SHA"
local base = "https://raw.githubusercontent.com/OWNER/REPO/" .. commit .. "/dist/"
local loader = assert(loadstring(game:HttpGet(base .. "loader.lua")))
local ss = loader({
    bundle_source = "url",
    bundle_url = base .. "shadowscan.bundle.lua",
    allowed_place_ids = { 1234567890 },
})
ss:passive_scan()
ss:summary()
```

URL mode requires the executor to expose `request` or `http_request` for the bundle download. Verify `dist/loader.lua` out-of-band against `dist/RELEASE.json` before first execution; the loader verifies the downloaded bundle itself.

---

## 2. Running an audit

The quickest path is the GUI: run the loader, click **Scanner -> Start Passive Scan**, review **Findings**, then **Secure Export -> Build Report -> Encrypt and Save** while the Companion window is open (it shows the one-time pairing token and a ready-to-paste line). The console API below does the same things and is what the tests drive.

### Passive audit (sends nothing)

In your executor console:
```lua
local ss = loadstring(readfile("ShadowScan/loader.lua"))({
    allowed_place_ids = { 1234567890 },   -- recommended: refuse to run anywhere else
})
ss:passive_scan()       -- PASSIVE INVENTORY STARTED ... CANDIDATES GENERATED
ss:summary()            -- counts only (safe to paste anywhere)
```

### Save the report - encrypted

Terminal 1 (your PC):
```powershell
python shadowscan.py companion --formats json,md,html
```
It prints a **one-time pairing token** (`ssp_...`, valid 10 minutes, single use) and the port.

Executor:
```lua
ss:build_report()
ss:save_encrypted({ token = "ssp_...", port = 47821 })   -- REPORT ENCRYPTED / REPORT SAVED
```
Encrypted files appear in `reports_encrypted\` as `shadowscan-<audit id>.report.{json,md,html}.age`. In the GUI, **Secure Export -> Export Encrypted TXT** additionally writes `ShadowScan_Audit_YYYYMMDD_HHMMSS.txt` (armored ciphertext) with a `.sha256` sidecar, and **Save Metadata** writes a small metadata file - ciphertext and metadata only, never report content ([docs/REPORT_FORMAT.md](docs/REPORT_FORMAT.md)).

**If your executor cannot reach localhost**, use the explicit, loud fallback and encrypt offline:
```lua
ss:export_unencrypted({ acknowledge = "I UNDERSTAND THIS REPORT IS NOT ENCRYPTED" })   -- writes ShadowScan/out/<id>.UNENCRYPTED.json
```
```powershell
python shadowscan.py encrypt-file --in "<workspace>\ShadowScan\out\<id>.UNENCRYPTED.json" --delete-source
```
(`--delete-source` overwrites then deletes the plaintext; on SSDs and journaling filesystems secure deletion cannot be guaranteed.)
ShadowScan never claims a fallback export is encrypted.

### Read a report

```powershell
python shadowscan.py decrypt --identity $HOME\.shadowscan\me.key --in reports_encrypted\shadowscan-<id>.report.md.age --out report.md
```

---

## 3. Active tests (developer-approved only)

1. The developer (or you, with their written approval) writes a **test manifest** - see [docs/MANIFEST.md](docs/MANIFEST.md) and `test_manifest/examples/`.
2. Check it on your PC: `python shadowscan.py manifest validate manifest.json`
3. In the executor:
```lua
ss:load_manifest_file("ShadowScan/manifest.json")   -- APPROVED TEST PLAN LOADED
ss:preview_manifest()                               -- prints the plan and the exact confirmation phrase
ss:active_run({ dry_run = true })                   -- DRY RUN ONLY: NOTHING was sent
ss:active_run({ confirm = "APPROVE <manifest id> <plan hash>" })   -- phrase is bound to the exact plan
-- mutating tests also need:  reset_confirmed = true  (after you prepared the QA reset the manifest describes)
```
Blocked runs say why (`ACTIVE TEST BLOCKED: ...`). Production observation allows only non-mutating, justified tests; state-changing tests require a private QA server and a reset procedure.

### Command reference (`ss:` methods)

| Method | What it does |
|---|---|
| `target_check()` | Checks `allowed_place_ids` (and prints TARGET CHECK PASSED/FAILED) |
| `passive_scan()` | Starts a **new** audit: inventory + candidates. Never merges with earlier audits |
| `load_manifest_file(path)` / `load_manifest_string(text)` | Validate + load an approved test plan |
| `preview_manifest()` | Show plan, limits and the required confirmation phrase |
| `active_run{dry_run, confirm, reset_confirmed}` | Dry run, or the real run behind all gates |
| `summary()` | Non-sensitive counts only |
| `build_report()` | Build the JSON report (minimised, redacted) |
| `save_encrypted{token, port}` | POST to the loopback companion; encrypted on arrival |
| `export_unencrypted{acknowledge}` | Explicit plaintext export (fallback) |
| `discard()` | Wipe the in-memory audit |
| `start_live()` / `stop_live()` / `drain_live()` | Passive live observation: record newly replicated objects of interest (sends nothing) |
| `save_snapshot()` / `compare_snapshot_file(path)` | Save the remote-surface fingerprint / compare against a saved one |
| `draft_manifest{}` / `export_manifest_draft()` | Generate a manifest DRAFT from top-risk candidates (invalid until approved) |
| `refresh_inventory()` | Re-derive candidates from the observations already in memory |
| `capability_report()` | The runtime capability report (also in reports and on the Settings page) |
| `set_profile(key)` | Switch the performance profile: low_impact / balanced / fast |

Config keys (passed to the loader): `allowed_place_ids`, `minimize` (default true), `anonymize_tester` (true), `tester_label`, `include_job_id` (false), `scan_roots`, `max_objects`, `companion_port`, `bundle_source` (`workspace`|`url`), `bundle_url` (pinned only).

---

## 4. Run the tests

```powershell
python -m pytest                      # Python tests + the whole Luau suite (Luau tests are SKIPPED, not passed, if the Luau CLI is absent)
python tools\run_luau_tests.py        # Luau suite on its own
```
Install the test tools first: `python -m pip install -r requirements-dev.txt`. The **desktop UI tests** open real Tk windows on a virtual display (Linux: `xvfb-run`; they are SKIPPED, not passed, where that is unavailable, e.g. plain Windows). The **age interoperability test** needs the official `age` binary (`AGE_BIN=path`); otherwise it is skipped.
Luau tests need the standalone Luau CLI (https://github.com/luau-lang/luau/releases -> `luau-windows.zip`); set `LUAU_BIN` to `luau.exe`
or put it on PATH. Actual results from the development environment: [docs/TEST_RESULTS.md](docs/TEST_RESULTS.md).

Regenerate derived files after editing sources: `python tools/gen_tokens.py`, `python tools/gen_schemas.py`, `python tools/gen_fixtures.py`, `python shadowscan.py build`, `python tools/gen_examples.py`, `python tools/gen_screenshots.py`, `python tools/gen_test_results.py`.

## 5. Repository layout

```
loader/          loader template (pinned version + SHA-256 gate); built into dist/loader.lua
client/          session API (main.lua), executor adapter, util (JSON, SHA-256, secrets)   [Luau]
client/ui/       Roblox GUI: tokens, layout grid, scene components, pages, controller, renderer [Luau]
desktop/         Companion + Decryptor apps (Tkinter), shared widgets/theme, UI self-tests   [Python]
design/          tokens.json - the single source of colours, spacing, sizes and type
scanner/         passive inventory, rules, analyzer, verdict logic, active runner          [Luau]
test_manifest/   manifest validator (Luau + Python), JSON Schema, examples
reporting/       report builder [Luau]; schema, validation, rendering, redaction [Python]
companion/       loopback encryption server, pairing token, storage                        [Python]
encryption/      age wrapper, recipients, key generation                                   [Python]
tools/           build, schema/fixture/example generators, Luau test runner
tests/           pytest suite, Luau suite (tests/luau), synthetic fixtures
docs/            architecture, install (Windows), encryption, report format, recipients, manifest, compatibility, AI, performance + benchmark, limitations, release, test results
dist/            built bundle, loader and RELEASE.json (committed so hashes can be verified)
examples/        sample reports produced by the real pipeline on a FAKE game
```


## 0.4.3 hotfix

The 0.4.3 hotfix captures the executing script's `game` global explicitly for runtime metadata and service access, and makes the in-game UI respect Roblox safe insets. Executor compatibility still requires validation in the target environment.
