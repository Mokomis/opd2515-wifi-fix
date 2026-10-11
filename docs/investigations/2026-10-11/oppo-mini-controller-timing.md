# Kishi controller timing

2026-10-11. Read-only, no controller or bridge changes. Razer Kishi V3 Pro1532:0724 via installed RumbleBridge virtual controller.

USB high-speed480Mbps, interrupt-IN endpoint advertises125us interval. This is a polling opportunity, not measured report cadence. Continuous-stick capture delivered11,408 SYN_REPORT frames over15.006sec, typical interval1.001ms, p95 interval1.999ms. Overall average760/sec is affected by sparse/change-driven reporting and a998ms gap; without raw USB packet capture that gap is not attributed to controller transport failure.

Bridge cumulative counters differed by11,822 batches over the before/after status interval.95.51% were under100us,99.983% under500us;2 were500–1000us and none above1ms in the delta. Lifetime max13.993ms predates this capture and is not this test’s max. The mean printed by status is lifetime, rounded integer data, so no per-window mean is claimed. Status publication is periodic, so this interval differs from the exact15sec getevent window; batch and event counts need not match.

Installed daemon SHA25691865290685d30c91b4fba7e614d593755d1179cdbb7f2b4b76d65c5237bc9ba matches local build. Source sets physical evdev clock to CLOCK_MONOTONIC and measures first event timestamp through completed virtual-pad write. This covers kernel-event-to-bridge-write, not physical actuation, Android dispatch, app consumption or button-to-screen. Source forwards input directly after poll signals readable;500ms poll timeout does not intentionally delay a ready event.

No worthwhile input-forwarding optimization demonstrated. Evidence: work/controller-timing/connected-input.txt, connected-usb.txt, status-before/after.txt, stick-events.txt and metrics.json. Raw device details remain local.
