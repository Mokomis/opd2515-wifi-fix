# REA Android bridge repair

Installed the version-pinned, checksum-verified JADX headless MCP 0.7.1 JAR at `~/.local/share/rea/jadx/jadx-headless-mcp-0.7.1-all.jar` from its [upstream release](https://github.com/1013503897/jadx-headless-mcp/releases/tag/v0.7.1).

SHA-256: `6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75`, matched against the release asset digest.

Changed only `[mcp_servers.rea.env]` in `~/.codex/config.toml`: bridge JAR path and existing full Java 21 JDK path. Parsed before/after configuration and verified every other configuration value stayed identical. No unrelated tools, skills or tablet settings changed.

Configuration backup: `~/.codex/config.toml.rea-android-backup-20261011T050619Z`.

## Verification

The same REA 6.3.0 backend successfully performed:

- APK inspection: Athena 6.0.1, package com.oplus.athena; Evidence `ev_a0c3940594686d8bfac35e7ef6609bf401abf896d733c746477d2d85516b7382`.
- Class method inventory: AlwaysAliveManager; Evidence `ev_2567d45fe2aac1e33d7c84b94d3cf4f549648cdacfd0ff0b0afe5d266d9a381b`.
- Method decompilation: its exact method `f`, overload 0; Evidence `ev_44aa0ef17b23d948ea5159598bccb3a3d50664c940184bddeaad55e488f721a5`. Body available in java, source complete.

Initial method lookup using the guessed name getInstance returned not-found; the final test uses the method selector and overload from the verified inventory.

## Activation

After the user restarted Codex, the current chat's dedicated `inspect_android_method` tool successfully decompiled Athena's AlwaysAliveManager.f overload 0. Java source was complete with no fallback. Evidence `ev_b98c3f5a3cd8c9dcda184985852ba0f2244dbee003bb429fcb8a19d8e3ba14c1` is retained in `work/freeze-rea/bridge-mcp-restart-verified.json`. Activation is confirmed; no further restart or repair is needed.

Raw tests and setup diagnostics are in `work/freeze-rea/bridge-*.json`, `repair-doctor.json`, and `repair-setup-plan.json`. Broad setup was not applied, since only the missing Android provider needed repair.
