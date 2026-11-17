# AngelOS next improvements

## Primary goal

Make the six selected areas safer and easier to use in the AngelOS fork, while extending the existing systems instead of duplicating them. A completed change must have a clear user-facing benefit, fit AngelOS's current patterns, and have a regression check or explicit evidence that the existing feature already covers it.

## Phase 0: Documentation discovery (complete)

**How this serves the primary goal:** Establishes what AngelOS already provides so this work closes real gaps and preserves its safety boundaries.

- Read `CLAUDE.md`, `installer/README.md`, the Russian and English READMEs, and the source for recovery, update transactions, games, laptop power, settings diagnostics, and reports.
- Confirmed recovery and updater already have safe snapshots/rollback; game doctor already preserves prefixes and refuses destructive actions while a game is running; laptop has adaptive eco mode and power-profile integration; Settings has Maintenance and a scrubbed report CLI.
- Confirmed gaps: Recovery restore has no explicit confirmation in the UI, game-doctor lacks focused regression tests, and the report CLI is not directly discoverable from Settings → Maintenance.
- Allowed patterns: `CatGroup`/`CatButton`/`CatNote` in catalog QML; Settings tree in `modules/settings/tree.json`; `Recovery` service methods; Python scripts with throw-away HOME/sysfs/Steam roots in tests; report creation through `angelos report` / `scripts/report.py`.
- Anti-patterns: duplicate backup or updater engines; imply file snapshots roll back pacman packages or the full OS; delete Proton prefixes; change game launch options; wake the discrete GPU to report power; enable updates without a user click; add unsupported laptop power controls.
- References: `.config/quickshell/angelos/services/Recovery.qml`; `modules/settings/catalog/Account.qml`; `scripts/recovery.py`; `scripts/update-txn.py`; `scripts/dotfiles-update.sh`; `scripts/game-doctor.py`; `modules/settings/catalog/Battery.qml`; `services/Power.qml`; `services/Care.qml`; `modules/settings/catalog/Care.qml`; `scripts/report.py`; `installer/README.md`.

## Phase 1: Backups and rollback

**How this serves the primary goal:** Makes restoring account settings deliberate and understandable while preserving the existing automatic before-restore backup.

- Add a two-step confirmation to GitHub recovery restore in `modules/settings/catalog/Account.qml`; show that AngelOS saves the current state before replacing it.
- Keep file import separate and retain its existing backup-before-restore behavior.
- Add regression coverage for confirmation and the recovery archive round trip, including allowlisted paths and preserving the pre-restore copy.
- References: `Account.qml` recovery group; `services/Recovery.qml`; `scripts/recovery.py`; `tests/settings` harness patterns.
- Verify: recovery-focused tests and the settings tree/catalog checks.
- Guard: never restore silently; never claim full-system or package rollback.

## Phase 2: Update reliability

**How this serves the primary goal:** Keeps the existing transactional updater trustworthy and makes its supported recovery boundary clear.

- Audit existing interrupted-update, restore-conflict, and failed-install behavior; add only a missing regression case if a concrete gap is found.
- Document that snapshots cover AngelOS-managed files and preserve user edits, while Arch packages require package-manager or filesystem snapshot recovery.
- References: `scripts/test-update.sh`; `scripts/update-txn.py`; `scripts/dotfiles-update.sh`; `modules/settings/catalog/Updates.qml`; README update sections.
- Verify: existing update test suite and documentation links.
- Guard: no automatic install, destructive reset, or claim that a user-file snapshot rolls back pacman.

## Phase 3: Games

**How this serves the primary goal:** Protects the existing game repair actions with focused evidence, so troubleshooting remains safe and predictable.

- Add isolated tests for game discovery, refusing to reset a running game's prefix, preserving moved prefixes, refusing shader-cache removal while games run, and the stable JSON result contract.
- Reuse throw-away Steam libraries and mock system commands; never access the real user's Steam library in tests.
- References: `scripts/game-doctor.py`; `modules/settings/catalog/Care.qml`; `services/Care.qml`; `tests/laptop` and other Python unittest patterns.
- Verify: the new test file and `scripts/check.sh` integration.
- Guard: no changes to Proton selection, launch options, real prefixes, or real shader caches.

## Phase 4: Laptop power

**How this serves the primary goal:** Confirms that the existing notebook controls stay hardware-aware and do not override user-selected power profiles unexpectedly.

- Audit the existing eco threshold, power-saver profile handoff, GPU status, charge-limit capability detection, and laptop tests; add a focused regression only for a real uncovered edge case.
- Document unsupported hardware behavior and settings paths in the user guide.
- References: `modules/settings/catalog/Battery.qml`; `modules/settings/catalog/Laptop.qml`; `services/Power.qml`; `services/Laptop.qml`; `tests/laptop`.
- Verify: laptop test suite and QML validation.
- Guard: no fabricated charge-limit support, no GPU wakeups, no unconditional profile changes.

## Phase 5: Settings and diagnostics

**How this serves the primary goal:** Lets a user create a privacy-scrubbed diagnostic archive from the existing Maintenance page without searching for a terminal command.

- Add a clearly labelled report action and a short privacy/scope note to Settings → System → Maintenance, using the existing report command and behavior.
- Ensure the Settings tree already exposes the relevant group and keep the existing one-click health scan.
- References: `modules/settings/catalog/Care.qml`; `modules/settings/tree.json`; `scripts/report.py`; `bin/angelos`.
- Verify: settings tree test, QML validation, and a report-script test in a throw-away HOME.
- Guard: do not send or upload reports automatically; preserve the current scrubber and local archive destination.

## Phase 6: User documentation

**How this serves the primary goal:** Gives Russian and English readers one accurate guide to backups, updates, games, laptop power, and diagnostics.

- Add a concise guide linking existing Settings pages and commands, noting what is saved, how to recover, what update snapshots do not cover, and where diagnostic archives are written.
- Add links from both README language versions and the installer guide where appropriate.
- References: `README.md`, `README.ru.md`, `installer/README.md`, feature source and CLI help text.
- Verify: links point to existing pages/commands and examples match their actual CLI syntax.
- Guard: no unsupported feature claims and no omission of destructive-action safeguards.

## Phase 7: Verification

**How this serves the primary goal:** Proves the new safety affordances work and that all six areas remain coherent after the edits.

- Run focused Recovery, game-doctor, updater, laptop, settings-tree, report, and QML checks; review the complete diff and run `graphify update .` if graphify is available.
- Confirm no unrelated files or existing user state were modified.
- Do not commit or push unless the user separately asks to publish.
