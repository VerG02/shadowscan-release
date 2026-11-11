# Architecture (0.6.1 Standalone Runtime Intelligence Edition)

Two independent analysis engines sharing a common framework:

```
RUNTIME ENGINE (primary)                    STATIC ENGINE (optional)
  Inventory scan (bounded batches)            Paste Luau source
  -> observations                             -> comment-aware pattern matching
  -> analyzer (evidence-first findings)       -> 19 rules + 4 correlations
  -> classify (14 families + provenance)      -> evidence with line numbers
  -> risk (priority/confidence/status)        -> severity/confidence
  -> graph (factual relationships)            -> bounded report
  -> live observation (passive)               -> independent of runtime evidence
  -> snapshots + comparison
-> combined plaintext report (origin-labeled)
-> clipboard / TXT export (capability-detected)
```

## Module structure

| Module | Responsibility | Key invariant |
|---|---|---|
| `src/config.lua` | Limits, severity scale, UI constants | No external files or services |
| `src/util.lua` | Text helpers, capability detection, error cleanup | No module-level mutable state |
| `src/secrets.lua` | Sensitive-value detection (for inventory, not source) | Values never stored, only type/length/flag |
| `src/inventory.lua` | Bounded passive scan of replicated DataModel | Never fires remotes, never modifies game |
| `src/classify.lua` | Functional family classification with provenance | Unknown is a legitimate result |
| `src/analyzer.lua` | Evidence-first findings from observations | Names alone never prove vulnerabilities |
| `src/risk.lua` | Three-dimensional scoring (priority/confidence/status) | Priority != confirmation |
| `src/graph.lua` | Factual relationship graph (bounded) | No implied communication from shared parent |
| `src/live.lua` | Passive live observation (bounded buffer) | Never fires remotes; never modifies game |
| `src/snapshots.lua` | Snapshot creation, comparison, save | Disappearance != deletion (disclosed) |
| `src/static_rules.lua` | 19 static detection rules + 4 correlations | Patterns match code, not comments |
| `src/static_engine.lua` | Comment-aware source scanning | Never executes analyzed source |
| `src/report.lua` | Dual-mode plaintext report generation | Origin-labeled; evidence-first |
| `src/export.lua` | Clipboard/TXT with capability fallbacks | Never claims success without capability |
| `src/ui.lua` | Compact declarative renderer | Diff-based instance reuse |
| `src/app.lua` | 8-page layout (pure data) + dispatch | All controls functional |
| `src/session.lua` | Runtime state: inventory, findings, graph, live | Scanner never fires remotes |
| `src/main.lua` | Entry point: console API + UI bootstrap | Same engine for console and UI |

## Evidence separation

Runtime evidence (object names, paths, metadata, structure) is always labeled RUNTIME. Static evidence (source patterns, line numbers) is always labeled STATIC. The combined report clearly separates the two sections and never mixes evidence models.

## Build

`tools/build_standalone.py` inlines all modules into one file using the factory registry pattern. Builds are deterministic (same sources → same bytes).
