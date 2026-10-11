# OPPO Mini follow-up notes

2026-10-11

## Buffer investigation parked

User chose to move on unless another investigation has a clear potential gain. Keep the permanent Punktfunk-only value2 setting with alignment enabled. No further frame-timeline validation or app instrumentation planned. Permanent helper was not paused or changed during the abandoned frame-timeline availability check.

## Faster touch reporting — future option

Measured delivered touch-event rate increased from approximately151 to275 reports/sec under the temporary faster selector. Original touch selector was restored afterward; this mode is not permanently enabled. Potential benefit is local touchscreen responsiveness, not direct controller input responsiveness. End-to-end touch latency, power/thermal impact and long-term behavior remain unmeasured. Revisit only if user wants to improve touch interaction.

Evidence: oppo-mini-touch-and-buffer-options.md. Buffer results and installation: oppo-mini-buffer-value2-results.md, oppo-mini-buffer-alignment-results.md, oppo-mini-buffer-producer-wait-results.md, oppo-mini-buffer-permanent.md.
