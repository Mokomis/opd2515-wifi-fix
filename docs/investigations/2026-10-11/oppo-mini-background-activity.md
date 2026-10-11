# OPPO Mini background activity during streaming

Read-only check of the restored original app. Twelve five-second CPU intervals (first refresh discarded), plus seven per-UID BPF network snapshots spanning 30.06 seconds. No app, service, property, scheduling, or network setting changed.

The leading CPU users were the foreground stream, Wi-Fi receive handling, and display components. Device CPU idle averaged 72.1% across eight cores. This does not rule out momentary per-core contention.

| Process | Mean CPU | Highest five-second interval |
|---|---:|---:|
| io.unom.punktfunk.mokomis | 61.83% | 65.00% |
| [dp_rx_thread_0] | 55.90% | 59.00% |
| [crtc_commit:208] | 18.17% | 20.40% |
| surfaceflinger | 11.85% | 13.80% |
| [dp_refill_thread] | 6.62% | 7.00% |
| vendor.oplus.hardware.urcc-service | 0.98% | 1.20% |
| oiface | 0.28% | 0.60% |
| com.oplus.onetrace | 0.22% | 0.60% |
| vectord | 0.20% | 0.40% |
| com.oplus.subsys | 0.17% | 0.60% |
| com.oplus.cosa | 0.10% | 0.20% |
| horae | 0.08% | 0.20% |
| com.oplus.midas | 0.07% | 0.20% |
| vendor.oplus.hardware.gameopt-service | 0.07% | 0.20% |
| com.oplus.nas | 0.03% | 0.20% |
| com.oplus.location | 0.02% | 0.20% |
| com.oplus.metis | 0.02% | 0.20% |
| com.oplus.padconnect | 0.02% | 0.20% |
| vendor-oplus-hardware-oplusSensor-V1-service | 0.02% | 0.20% |
| com.oplus.persist.multimedia | 0.02% | 0.20% |

CPU percentages use one core as 100%%; the device has eight cores. Only the busiest 40 processes were retained per sample, so averages for intermittently absent services are lower bounds; absence does not prove zero activity. Five-second sampling can miss short spikes. Memory and I/O pressure averages stayed at zero; CPU pressure remained around 8.6%%, a measure of task waiting rather than overall utilization.

The stream UID accounted for 99.99174% of recorded per-UID bytes. Other UIDs excluding our shell contributed 101,581 bytes in total. System shared UID 1000 transferred only 252 bytes; its activity cannot be attributed to an individual package. `com.oplus.location` and `com.oplus.framework.network.drs` showed no counter increase. UID 1020 accounted for 101,329 bytes; package-list attribution was unavailable. Shell traffic includes collection overhead. These are Android BPF per-UID accounting values, not a physical Wi-Fi airtime measurement.

No OPPO background service showed enough sustained CPU or network activity to justify a disabling experiment from this sample. Keep the services unchanged. A future targeted capture should be triggered by an actual hitch to establish whether a short service burst coincides with it; this capture alone does not establish causation.

Evidence: `work/background/top.txt`, before/after process and pressure snapshots, `netstats-0.txt` through `netstats-6.txt`, `network.json`, and `metrics.json`. The two netd dumps lacked per-UID counters and were not used for network calculations.
