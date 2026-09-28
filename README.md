# Fusekite

**Truth table in. A small-gate estimate out.**

Fusekite is a MoonBit project for reducing small combinational circuits and, over time, turning the result into a practical gate-level plan for electronics labs. It focuses on the gap between a classroom Boolean expression and a circuit someone can wire with common 74HC parts.

## Current stage

Fusekite validates a single-output truth table, builds deterministic Quine–McCluskey merge rounds and a minterm-to-prime chart, identifies essential implicants, and chooses an exact minimum SOP cover. Don't-care rows can help form implicants; a prime that covers only don't-care rows is left out. It also estimates a direct SOP gate count, maps that estimate to a small sourced 74HC catalog, and includes three worked circuit examples with independent truth-table checks.

This scope is intentionally bounded to one output and at most eight inputs. Fusekite is an educational planning aid, not a substitute for datasheet checks, timing analysis, or electrical safety review.

## Example

For `F(A, B, C) = Σm(1, 3, 5, 7)`, the required rows all have `C = 1`. Fusekite produces the minimum cover `--1`, which corresponds to `F = C`.

```moonbit
let spec = TruthSpec::new(3, [1, 3, 5, 7], [])
let solution = minimize_sop(spec.unwrap())
println(solution.patterns()) // ["--1"]
```

Run all three electronics demonstrations with:

```sh
moon run cmd/main
```

The demo prints each selected cover, primitive gate count and a whole-package
estimate for SN74HC04/08/32. Device assumptions and full truth tables are in
[`circuits/WORKED.md`](circuits/WORKED.md); the sourced catalog is described in
[`parts/74hc-catalog.md`](parts/74hc-catalog.md).

## Implemented milestones

1. **Truth-table refinement and SOP cover** — explicit validation, coverage chart, essential implicants, and deterministic exact selection.
2. **Bench planning** — two-level gate estimates, a TI-sourced 74HC catalog, and three circuit examples with independent truth-table checks.

## Planned work

1. Add POS presentation and tests without changing the current SOP contract.
2. Add pin-level wiring guidance only for exact device variants after datasheet review; physical qualification remains out of scope until actually performed.

The examples cover a two-sensor interlock, one BCD-to-seven-segment output, and a threshold/alarm condition.

## Project shape

The core is a single root MoonBit package so the Boolean rules can be read in one place. `coverage.mbt` exposes row-to-prime relationships, `cover.mbt` contains exact selection, and `gate_cost.mbt` provides primitive counts. The `parts/` package contains a small sourced catalog; `circuits/` contains examples and independent checks; a small executable lives under `cmd/main`.

## Build and test

```sh
moon fmt --check
moon check --deny-warn
moon test
moon build
moon run cmd/main
moon doc
moon package --list
```

The GitHub Actions workflow pins an Ubuntu LTS image and a Node 24-compatible
checkout action, then runs formatting, check, tests, build, and the demo on
pushes to `main` and pull requests.

See [DEVELOPMENT.md](DEVELOPMENT.md) for the contribution boundary, reproducible
checks, and the maintainer review items that remain before submission.

## Mooncakes metadata

This module is named `Lyhdsba/fusekite` and its current metadata is in
[`moon.mod`](moon.mod): version `0.2.0`, Apache-2.0 license, repository URL,
keywords, and a short description. The repository URL also serves as its
project homepage. To publish a version after logging in to Mooncakes,
review and increment the semantic version as appropriate, then run:

```sh
moon publish
```

Publishing is a separate release action; this repository change prepares the
metadata and package contents but does not publish a package.

## License

Apache-2.0. See [LICENSE](LICENSE).
