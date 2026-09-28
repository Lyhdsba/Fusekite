# Fusekite

**Truth table in. A breadboard-sized logic plan out.**

Fusekite is a MoonBit project for reducing small combinational circuits and, over time, turning the result into a practical gate-level plan for electronics labs. It focuses on the gap between a classroom Boolean expression and a circuit someone can wire with common 74HC parts.

## Current stage

Fusekite validates a single-output truth table, builds deterministic Quine–McCluskey merge rounds and a minterm-to-prime chart, identifies essential implicants, and chooses an exact minimum SOP cover. Don't-care rows can help form implicants; a prime that covers only don't-care rows is left out. POS output and physical IC planning remain planned work.

This scope is intentionally bounded to one output and at most eight inputs. Fusekite is an educational planning aid, not a substitute for datasheet checks, timing analysis, or electrical safety review.

## Example

For `F(A, B, C) = Σm(1, 3, 5, 7)`, the required rows all have `C = 1`. Fusekite produces the minimum cover `--1`, which corresponds to `F = C`.

```moonbit
let spec = TruthSpec::new(3, [1, 3, 5, 7], [])
let solution = minimize_sop(spec.unwrap())
println(solution.patterns()) // ["--1"]
```

Run the demo with:

```sh
moon run cmd/main
```

## Planned work

1. **Truth-table refinement and SOP cover** — implemented with explicit validation, coverage chart, essentials, and deterministic exact selection.
2. **Bench planning** — compare gate count and common 74HC implementations, with pin-level notes and worked electronic-lab examples.
3. **POS and circuit checks** — add POS presentation and independent truth-table verification for the finished plans.

The planned examples are a two-sensor interlock, one BCD-to-seven-segment output, and a threshold/alarm condition. They are separate from waveform processing, PCB/stock optimization, and agent audit tooling.

## Project shape

The core is a single root MoonBit package so the Boolean rules can be read in one place. `coverage.mbt` exposes row-to-prime relationships and `cover.mbt` contains exact selection; a small executable lives under `cmd/main`. Device data and worked circuits will live under `parts/` and `circuits/`.

## Build and test

```sh
moon check
moon test
moon fmt --check
```

## License

Apache-2.0. See [LICENSE](LICENSE).
