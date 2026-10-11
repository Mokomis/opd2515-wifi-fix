# OPPO Pad Mini OPD2515 — device file inventory

Read-only root-access snapshot collected2026-10-11 from the connected Mini. This is an inventory-first handoff for further configuration research, not a claim that every configuration has been identified or explained.

## Coverage and counts

- **457,229 filesystem entries** enumerated locally:363,203 regular files,50,770 directories,43,051 symbolic links and205 other entries. No traversal errors were reported in the included paths; the command exited0.
- **30,952 entries** published in the sanitized filesystem manifest. Most personal/app/cache/log/media paths and protected persistent stores are withheld from publication. The complete raw path/metadata manifest remains local.
- **9,291 standalone candidates**, selected broadly from configuration directories, file suffixes and OEM policy stores. These include false positives and generic Android/Qualcomm resources, not9,291 verified OPPO configs.
- **1,087 containers** listed:1,047 stock/system containers plus40 APKs from37 updated OEM apps, including split APKs.
- **1,052,547 archive-member records**, of which802,211 were broad configuration/resource candidates. This includes assets, XML resources, manifests and compiled resource tables. Repeated mounted versions/copies and common resources are not deduplicated; these counts are not numbers of distinct OPPO configurations.
- All25 previously collected configuration paths are present in the fresh scan and published manifest.

The scan traversed the root namespace visible to the root shell, including /system, /system_ext, /vendor, /product, /odm, /my_*, mounted APEX/OPEX resources, firmware mounts and /data. It did not follow symlinks. Virtual /proc, /sys, /dev and /config trees were excluded, as were data_mirror and duplicate emulated-storage views. Primary /data/media metadata was included locally. See [mount coverage](mount-coverage.json) and [summary](summary.json) for exact boundaries.

## Files for Claude or other researchers

| File | Contents |
|---|---|
| [filesystem-manifest.jsonl.gz](filesystem-manifest.jsonl.gz) | Public paths and metadata, one JSON record per entry. Includes directories and symlinks. |
| [configuration-candidates.jsonl.gz](configuration-candidates.jsonl.gz) | Standalone candidates with selection reasons. Candidate status is heuristic, not verified semantics. |
| [archive-members.jsonl.gz](archive-members.jsonl.gz) | Container path, member name and uncompressed member size from ZIP listings. |
| [embedded-configuration-candidates.jsonl.gz](embedded-configuration-candidates.jsonl.gz) | Broad embedded-resource subset; not a list of definitively identified configurations. |
| [archive-coverage.json](archive-coverage.json) | Every listed container, entry count and listing exit code. No listing failures were reported. |
| [property-names.json](property-names.json) | Runtime Android property names only; values omitted. |
| [settings-names.txt](settings-names.txt) | Keys in system, secure and global settings; values omitted. |
| [runtime-services.txt](runtime-services.txt) | Registered Binder services/interfaces. |
| [mount-coverage.json](mount-coverage.json) | Mount points, filesystem types, mount roots and options. |
| [collection-method.json](collection-method.json) | Exact metadata walk command and exclusions. |
| [device-identity.txt](device-identity.txt) | Build fingerprint, model, Android version and security patch; no device serial. |
| [previous-inventory-reconciliation.json](previous-inventory-reconciliation.json) | Presence check for the previous25 config paths. |
| [summary.json](summary.json) | Counts, withheld categories, exclusions and limitations. |
| [HANDOFF.md](HANDOFF.md) | Instructions for Claude Cloud's inventory reconciliation and subsequent REA work. |
| [checksums.json](checksums.json) | SHA256 identities of these published inventory files, not hashes of tablet file contents. |

Download the gzip files rather than relying on GitHub's rendered page. They are standard gzip-compressed JSON Lines, readable with Python's gzip/json modules. No vendor APK, executable, config body, database content or personal app content is uploaded here.

## Collection method and limitations

The filesystem walk used Toybox find -printf with nine NUL-separated fields: path, type/mode string, numeric UID, numeric GID, size, inode, modification time, symlink target and octal permissions. NUL delimiting preserves filenames with whitespace/newlines. The device was unlocked and root access was used. File contents were not read by this walk. Archive listing used unzip -l without extraction; archive directory metadata was read. Runtime property values were collected locally but only names are published; settings collection requested names only.

This is a live, non-atomic snapshot. Files can change during the scan. Zero reported errors does not prove access to other mount namespaces, unmounted partitions, hidden encrypted storage or every possible device user. Alias paths remain represented in metadata where visited; some duplicate mount views were deliberately pruned. Objects outside the public subset may include configuration or state relevant to later analysis.

The public data includes stock/system paths, updated OEM APK directories, selected stable filenames in OEM policy stores, OEM shared_prefs/databases locations, and limited /data/system candidates. Unsafe-looking/generated filenames and most private data are omitted. This is conservative publication filtering, not proof that omitted files are irrelevant. The full unfiltered manifest remains available locally for targeted follow-up.

Archive listings do not recursively unpack nested archives or APEX payload images, parse compiled XML/resource tables, or find constants/resources embedded inside native libraries or DEX code. Mounted APEX contents are independently represented in the filesystem scan. Updated OEM APK selection used com.oplus/com.oppo/com.coloros/com.heytap/com.nearme package prefixes; other updated packages were not inspected as archives.

Use this inventory to expand and validate coverage before deep analysis. To establish actual formats, keys, defaults, consumers and precedence, additional sanitized configuration captures and matching consumer artifacts will be necessary. REA cannot derive these facts from filenames alone.
