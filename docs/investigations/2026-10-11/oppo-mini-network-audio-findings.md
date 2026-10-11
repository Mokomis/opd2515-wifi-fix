# OPPO Mini network and audio observation

Read-only capture during normal play. No stream settings, services, Wi-Fi policy, or host settings changed. The earlier scheduling rollback remains in place.

## Observations

- Audio log span: 120.0 seconds, 41 samples.
- Audio underruns stayed at 28; no new underruns during this window.
- Cumulative audio concealment (`plc_ms`) rose from 635 to 675, an increase of 40 ms. The change appeared in the sample at epoch 1791691594.050; logging bounds the event rather than locating its precise time.
- Audio target buffer fell from 90 to 25 ms. App-reported A/V value fell from 125 to 58 ms; this is not an end-to-end latency measurement.
- Wi-Fi signal samples ranged from -56 to -50 dBm, at 6375 MHz with Wi-Fi 7, 320 MHz link reports. Power save reported off throughout.
- Interface RX/TX errors and drops stayed zero. Station TX failures stayed 14; TX retries increased 1,428 over 111 seconds. These are tablet transmit counters, not proof that inbound video/audio experienced no wireless retries or loss.
- App wire diagnostics reported video rates of 910.6–1084.7 Mbps. A brief packet record independently contained 992.1 Mbps of incoming UDP payload, before accounting for missed records or protocol overhead.
- Saved Android settings say codec `pyrowave` and bitrate 200,000 kbps (200 Mbps). The observed traffic materially exceeds that saved value.

## Capture limits

Detailed packet recording was stopped after roughly 21 seconds because the high packet rate overloaded the recorder: 1,800,575 packets captured, 152,316 kernel capture drops. These are recorder drops, not demonstrated transport losses. Capture load could perturb the stream. Packet gap statistics from this record cannot establish network jitter or explain the later concealment event. The remaining observation used app logs and periodic Wi-Fi counters. No packet payloads were retained in the text output.

## Host-side finding and next test

The local Oct 3 host source in `work/host-source/crates/punktfunk-host/src/native.rs`, `resolve_bitrate_kbps_under`, explicitly ignores client bitrate for PyroWave, computes a host bits-per-pixel rate, and applies a host ceiling. The host configuration exposes `pyrowave_max_mbps` / `PUNKTFUNK_PYROWAVE_MAX_MBPS`. This explains a plausible way the saved Android bitrate can differ from observed traffic; the deployed host version and current cap have not been verified.

The next controlled test should first inspect the running host version, PyroWave bits-per-pixel setting, and host cap, then temporarily lower its actual rate and repeat the same observation. A host cap may reduce image quality and requires a new session in the examined source. Restore the original value afterward. Current evidence does not establish that an OPPO service causes the concealment, and it does not justify disabling another service.

Evidence: `work/network-test/app-log.txt`, `app-metrics.json`, `wifi-samples.txt`, `tcpdump-status.txt`, `packet-summary.json`, and filtered Android settings.
