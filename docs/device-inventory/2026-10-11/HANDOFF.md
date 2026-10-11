# Claude Cloud handoff: inventory first, configuration semantics second

Repository: https://github.com/Mokomis/opd2515-wifi-fix — latest main.
Start with docs/device-inventory/2026-10-11/README.md and summary.json. Download the compressed JSONL datasets and validate checksums.json. Then read FINDINGS.md and the earlier app-exception-list report.

## Phase 1: reconcile and classify the fresh inventory

Use the fresh metadata scan as the starting point, not the previous25-file sample. Reconcile filesystem paths, symlinks, visible mounts, archive members, property names, settings keys and services. Include generic Android/Qualcomm sources where OPPO consumes or overrides them. Preserve aliases and archive provenance; do not deduplicate identical-looking paths without evidence.

The full457,229-entry raw inventory is local. The public filesystem subset is30,952 entries; private paths and contents are intentionally withheld. Treat omitted categories, virtual trees, unmounted/other namespaces, nested archive payloads and unexamined updated packages as coverage gaps. Do not claim that every existing OPPO configuration is included. Candidate selection is deliberately broad and includes many false positives.

Produce a deduplicated candidate catalog, grouped by component and format, with status: confirmed config, likely config, resource/state/log/cache, unresolved, or unavailable. Initially most classifications will be provisional because config contents and consumer binaries are not uploaded. Account for all candidates programmatically; do not manually decompile hundreds of thousands of resource entries as if each were an independent policy file.

Compare against every configuration path referenced in the existing reports. Create a targeted acquisition checklist for additional config bodies, private structural metadata or matching APK/JAR/native artifacts needed locally. Configuration discovery remains open: consumer references found later must feed back into this inventory.

## Phase 2: explain identified configurations using REA

First verify REA and its required backends are installed and callable in this cloud session. Do not assume previous local REA IDs, Ghidra sessions or tablet access are available. Obtain matching publicly available artifacts where possible; record provenance and firmware/version mismatches. If artifacts are absent, explicitly mark the entry blocked and request the precise local extraction needed.

For each identified config, inspect its content/schema and use REA on readers and writers. Explain fields, types, defaults, units, accepted values, app matching, loading/update triggers, stock/vendor/downloaded/user/runtime precedence, resulting actions, gating conditions and restoration requirements. Cite exact artifact identities, classes/functions and evidence. Distinguish static code behaviour from observed runtime execution. Never infer semantics solely from a filename or report prose.

Deliver a machine-readable catalog, per-entry accounting, service/precedence diagrams where supported, acquisition checklist and coverage table. Work on a separate branch and publish through a pull request. Preserve historical reports and clearly qualify corrections.

This is research, not a new tuning campaign. Do not change device settings, re-enable the disabled buffer helper, upload personal data or copied vendor binaries without review, or start an Android/Linux port. Complete available work and report unresolved entries honestly.
