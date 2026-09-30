# Fusekite

**Boolean functions in. Canonical reasoning and a small-gate estimate out.**

Fusekite is a MoonBit Boolean-reasoning and electronics-planning library. It combines a canonical ROBDD representation and Boolean operations with a bounded exact SOP minimizer and a transparent 74HC gate estimate. The BDD layer is a reusable symbolic foundation; the circuit planner remains deliberately small and educational.

## Current stage

Fusekite provides a reduced ordered binary decision diagram (ROBDD) manager with a fixed variable order, unique-node reduction, memoized AND/OR/XOR application, complement, evaluation, and canonical equivalence checks. It can also independently check a selected SOP cover against a truth-table specification while masking don't-care rows. Alongside this foundation, Fusekite validates a single-output truth table, performs deterministic Quine–McCluskey refinement and exact minimum SOP selection, estimates direct SOP gate counts, and maps those estimates to a small sourced 74HC catalog.

The truth-table minimizer is intentionally bounded to one output and at most eight inputs. The ROBDD manager accepts 1–32 variables, but ROBDD size can grow exponentially for some functions; it is not a SAT/SMT solver and does not promise resource-bounded solving for arbitrary formulas. Fusekite is an educational planning aid, not a substitute for datasheet checks, timing analysis, or electrical safety review.

## Example

For `F(A, B, C) = Σm(1, 3, 5, 7)`, the required rows all have `C = 1`. Fusekite produces the minimum cover `--1`, which corresponds to `F = C`.

```moonbit
let spec = TruthSpec::new(3, [1, 3, 5, 7], [])
let solution = minimize_sop(spec.unwrap())
println(solution.patterns()) // ["--1"]
```

The ROBDD API can also be used without creating a truth-table specification:

```moonbit
let manager = BddManager::new(2).unwrap()
let a = manager.variable(0).unwrap()
let b = manager.variable(1).unwrap()
let both = manager.apply(BddOp::And, a, b).unwrap()
manager.evaluate(both, [true, false]) // Some(false)
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

1. **Symbolic Boolean foundation** — canonical ROBDD nodes, reduction and memoized Boolean apply, complement, evaluation, and equivalence.
2. **Truth-table refinement and SOP cover** — explicit validation, coverage chart, essential implicants, and deterministic exact selection, independently checked through BDDs.
3. **Bench planning** — two-level gate estimates, a TI-sourced 74HC catalog, and three circuit examples with independent truth-table and BDD checks.

## Planned work

1. Add POS presentation and tests without changing the current SOP contract.
2. Evaluate a SAT/CNF layer only after defining its input language, resource limits, and independent correctness oracle; no SAT/SMT solver is currently included.
3. Add pin-level wiring guidance only for exact device variants after datasheet review; physical qualification remains out of scope until actually performed.

The examples cover a two-sensor interlock, one BCD-to-seven-segment output, and a threshold/alarm condition.

## Project shape

The root MoonBit package contains the reusable ROBDD manager in `bdd.mbt`, truth-table refinement and cover selection in `fusekite.mbt`, `coverage.mbt`, and `cover.mbt`, and structural cost primitives in `gate_cost.mbt`. The `parts/` package contains a small sourced catalog; `circuits/` contains worked examples and independent truth-table/BDD checks; a small executable lives under `cmd/main`.

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

See [DEVELOPMENT.md](DEVELOPMENT.md) for the AI contribution statement,
reproducible checks, and validation limits.

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
