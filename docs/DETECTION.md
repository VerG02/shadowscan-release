# Detection documentation (0.6.0)

## Runtime detection (primary engine)

The runtime scanner inventories the client-visible DataModel and produces evidence-first findings. It discovers RemoteEvent, RemoteFunction and UnreliableRemoteEvent objects without executing them.

### Classification families (14)
Economy, Currency, Shop, Inventory, Rewards, Progression, Combat, Movement, Teleportation, Admin, Permission, Trading, Social, Unknown. Every classification records its basis (name/parent tokens), confidence, and the honest limitation that names are hints — never proof.

### Evidence types
- Object name pattern (weak indicator, capped at low severity)
- Parent path structure (weak indicator)
- Observed metadata (stronger: actual property values, access level)
- Structural correlation (multiple remotes in a related hierarchy)
- Source evidence (static analyzer, labeled separately)

### Correlation rules (SS-COR-001..004)
Network + loadstring → HIGH. Credential + network → CRITICAL. Auto-exec + loadstring → HIGH. Clipboard + credential → HIGH. These always annotate their basis and state that static analysis cannot prove data flow.

## Static detection (optional mode)

19 rules + 4 correlations over user-provided Luau source. Comment-aware matching, line-number evidence, bounded processing. Full definitions: `src/static_rules.lua`.

## Severity framework

CRITICAL / HIGH / MEDIUM / LOW / INFORMATIONAL. Three-dimensional scoring: Candidate Priority (0-100, investigation ranking), Evidence Confidence (low/medium/high), Verification Status (unverified/observed/confirmed).

## False-positive safeguards
- Weak evidence (name/location/structure only) capped at low severity
- Generic names don't create severe findings
- Unknown is a legitimate classification result
- Evidence deduplication
- Provenance preserved on every finding
