# ll-decision.md

## Decision
**A) Keep `ll_linux` + `ll_macos` + thin wrapper** for now.

## Inputs
- Performance report: `wip/ll-perf.md` (ll_macos is significantly slower than `/bin/ls -l`).
- Current correctness status:
  - GNU path (`ll_linux`) validated via `tests/ll_linux`.
  - BSD path (`ll_macos`) now has parity + color/time checks but remains early-stage.

## Rationale
- Performance gaps on macOS are large; unifying now risks spreading slower code paths to Linux.
- Separate implementations allow OS-specific optimizations (e.g., batching `stat` calls on macOS) without regressing Linux behavior.
- Wrapper contract is stable and already validated by common tests.

## Next Steps
- Optimize `ll_macos` collector (batch `stat`, reduce per-entry processes).
- Re-evaluate unification after performance improvements and broader parity coverage.
