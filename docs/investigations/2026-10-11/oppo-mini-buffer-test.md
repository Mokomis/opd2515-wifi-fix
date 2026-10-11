# Mini OPPO buffer-control test

> Historical investigation stage. Later runtime results and the current installed state are indexed in [README](README.md).

2026-10-11. Matching firmware inspected using REA/Ghidra; temporary per-process tests on the connected Mini. Original app and persistent configuration untouched.

## Result

Both Cosa-style values 1 and 2 reach the active app's graphics client. The reset returns that client to type 0/rate 0. This is a working request mechanism, but these captures do not demonstrate lower latency or actual queue-throttle execution. Leave it disabled for now.

## What the values mean

The exact libgui helper uses the value as a pending-frame threshold, not the total number of allocated buffers. Value 1 waits when pending frames reach 1; value 2 waits when they reach 2. Waiting is bounded by two display periods. With Cosa's non-strict setting, another alignment step targets the latest timestamp plus half a display period; strict mode omits that alignment while retaining the queue wait.

The mapped libguiextimpl integration has an additional gate: collect 360 producer timestamps and require mean producer interval no greater than 1.2 display periods. At 144 Hz that corresponds to roughly 120 fps. Slow or uneven rendering can prevent pacing even after the request arrives. Detailed static evidence is in work/cosa-rea/buffer-client-followup.md and client-*.json.

## Runtime evidence

The existing foreground process io.unom.punktfunk.mokomis, PID 26251, received:

- 00:35:41.722: type 4, rate 1, info true; client changes 0 to 4 / 0 to 1.
- 00:35:45.985: type 4, rate 2; client changes 1 to 2.
- 00:35:50.095: type 0, rate 0; client changes 4 to 0 / 2 to 0.
- A longer value-1 run, 00:36:31.290 to 00:36:40.601, also delivered and reset correctly. Producer-side BQPExtImpl logged OGFR initialization.

The longer run collected 1,175 unique valid SurfaceFlinger presentation records over 8.7 seconds. A graphics trace contains no executeOgfrControl marker; native debug gates also affect marker emission, so absence does not prove inactivity. That leaves actual throttle execution unresolved: initialization and callback receipt alone do not prove waiting or a latency improvement. Short rolling frame-history windows also overlap earlier frames and are not a controlled latency benchmark. No end-to-end input latency claim is made.

## Restoration

Each test used the unique description version-4-rea-buffer-test with the current PID/UID. The same request was reset to 0 in a finally block. An independent device-side 25-second watchdog repeated that reset. Runtime client logs confirm disabled state after both runs. Global FRTC, hybrid acceleration, refresh rate, touch rate, Cosa database, app build, and persisted settings were not changed. Graphics tracing was stopped.

Evidence directory: work/cosa-rea/buffer-runtime/ (request/reset responses, app mappings, full compositor dumps, rolling latency samples, client logs and graphics trace). The controls used were the traced seven-argument oplus_vrr_service frtc debug interface; ordinary FPS requests use different semantics, so the version-4 description is essential.
