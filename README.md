# Fusekite

**Truth table in. A breadboard-sized logic plan out.**

Fusekite is a MoonBit project for reducing small combinational circuits and, over time, turning the result into a practical gate-level plan for electronics labs. It focuses on the gap between a classroom Boolean expression and a circuit someone can wire with common 74HC parts.

## Current stage

The first increment provides a validated single-output truth-table model and deterministic Quine–McCluskey merge rounds. Don't-care rows can help form implicants; a prime that covers only don't-care rows is left out. The prime implicant cover solver and physical IC planner are still planned work.

This scope is intentionally bounded to one output and at most eight inputs. Fusekite is an educational planning aid, not a substitute for datasheet checks, timing analysis, or electrical safety review.

## Example

For `F(A, B, C) = Σm(1, 3, 5, 7)`, the required rows all have `C = 1`. Fusekite's first-stage refinement produces the implicant pattern `--1`, which corresponds to `F = C`.

```moonbit
let spec = TruthSpec::new(3, [1, 3, 5, 7], [])
let report = refine(spec.unwrap())
println(report.primes[0].pattern()) // --1
```

Run the demo with:

```sh
moon run cmd/main
```

## Planned work

1. **Truth-table refinement** — validation, implicant merging, and prime implicants.
2. **Cover selection** — choose a minimum two-level SOP/POS cover and show why each term is selected.
3. **Bench planning** — compare gate count and common 74HC implementations, with pin-level notes and a few electronic-lab examples.

The planned examples are a two-sensor interlock, one BCD-to-seven-segment output, and a threshold/alarm condition. They are separate from waveform processing, PCB/stock optimization, and agent audit tooling.

## Project shape

The core is a single root MoonBit package so the Boolean rules can be read in one place. A small executable lives under `cmd/main`; later device-selection data and worked circuits will live under `parts/` and `circuits/`. This avoids splitting a compact algorithm into artificial service layers.

## Build and test

```sh
moon check
moon test
moon fmt --check
```

## License

Apache-2.0. See [LICENSE](LICENSE).
