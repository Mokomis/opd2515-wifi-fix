# Touch-rate selector: screen-on idle interrupt check

2026-10-11. At the user's request, a short temporary test checked whether the faster touch selector increased host-visible touch-controller interrupts with no finger on the awake display. No permanent setting was enabled.

| Condition | HAL readback before/after | Touch IRQ delta | Duration | IRQ/sec |
|---|---|---:|---:|---:|
| Original current selector |0,12 /0,12 |12 |15.005sec |0.800 |
| Temporary faster selector |5,28 /5,28 |12 |15.001sec |0.800 |
| Restored original selector |0,12 /0,12 |12 |15.004sec |0.800 |

All three windows showed identical low idle interrupt counts. The faster setting did not increase host-visible touch IRQ activity in this short screen-on, untouched test. It was accepted and remained selected at both boundaries of its window. This supports no additional touch-interrupt load at idle under these conditions, not zero additional hardware power.

Method: root read of vendor.oplus.hardware.touch.IOplusTouch/default transaction3, device0/node182. The current original ordinal0 was recorded rather than assuming the earlier experiment's ordinal12. Temporary transaction4 write selected ordinal5, with3sec settling before each15sec observation. The touch-00 line in /proc/interrupts was summed across CPU columns before/after. PowerManager reported Awake after each observation. The user left a static screen untouched. A90sec delayed restore was armed before writes; finally restored ordinal0 and verified exact original0,12 readback, then cancelled the owned delayed-restore shell. No screen-off or active-finger capture was performed in this pass.

Limits: IRQ counts are not controller scan counts, input-event counts, CPU-time measurements or battery-power readings. The controller could scan faster internally without sending additional IRQs. The cause of the approximately0.8Hz idle IRQ activity was not classified. Three short windows on one static screen cannot establish all idle modes, longer-term power, or screen-off behaviour. Earlier active-finger tests measured delivered reports near151 versus275/sec using different original selection/readback; those results do not independently prove the current ordinal0's active cadence.

Conclusion: no observed extra idle interrupt activity. It remains unproven that power cost occurs only during touch. Exact power estimates remain unsupported; the earlier chat's low-single-digit expectation was a hypothesis, not a Mini measurement. Original setting restored; faster mode remains disabled as a permanent tweak. Broader research remains shelved.

[Compact results](metrics/touch-idle-interrupts.json). Raw interrupt snapshots and restoration readback remain local under work/touch-idle-test/.
