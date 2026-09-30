# Fusekite

**Boolean functions in. Canonical reasoning and a small-gate estimate out.**

Fusekite is a MoonBit Boolean-reasoning and electronics-planning library. It combines a canonical ROBDD, a bounded DPLL SAT backend with Tseitin CNF encoding, an exact small-table SOP minimizer, and transparent 74HC gate estimates. The symbolic layers can be used independently; the electronics planner is a tested application built on those foundations.

## Current stage

Fusekite provides a reduced ordered binary decision diagram (ROBDD) manager with a fixed variable order, unique-node reduction, memoized AND/OR/XOR application, complement, evaluation, and canonical equivalence checks. Its `sat/` package validates and normalizes CNF, parses DIMACS files, encodes Boolean expression trees with shared Tseitin subexpressions, and solves with deterministic DPLL propagation under an explicit search budget. The `smt/` package adds a bounded QF_BV bit-blasting front end: unsigned bit-vectors up to 8 bits, bitwise operations, wrapping add/subtract, low-product multiplication, equality, and signed/unsigned comparison. A SAT-backed verifier can return a concrete counterexample when an SOP cover is wrong. Alongside these foundations, Fusekite validates a single-output truth table, performs deterministic Quine–McCluskey refinement and exact minimum SOP selection, estimates direct SOP gate counts, and maps those estimates to a sourced 74HC catalog.

The truth-table minimizer is intentionally bounded to one output and at most eight inputs. The ROBDD manager accepts 1–32 variables, but BDD size can grow exponentially for some functions. The CNF solver accepts up to 4,096 variables, uses two-watched-literal propagation, and caps search at a caller-selected budget. The QF_BV layer bit-blasts into Boolean expressions and CNF; this is not a native theory solver or a complete SMT implementation. DPLL remains chronological and has no conflict learning or CDCL; hard formulas can return `Unknown` when the budget expires. Fusekite is an educational planning aid, not a substitute for datasheet checks, timing analysis, or electrical safety review.

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

The SAT package accepts DIMACS text, clauses, or a Boolean expression tree:

```moonbit
let expr = @sat.BoolExpr::Xor(
  @sat.BoolExpr::Variable(1),
  @sat.BoolExpr::Variable(2),
)
let formula = @sat.CnfFormula::from_expression(2, expr).unwrap()
let report = formula.solve(@sat.SolverConfig::new(10_000).unwrap())
```

For an existing DIMACS string, use
`@sat.CnfFormula::parse_dimacs(text)`; malformed headers, literals, and clause
counts return a typed error rather than a partial formula.

`SatOutcome::Unknown` is a budget result, never an unsatisfiability claim. See
[`DESIGN.md`](DESIGN.md) for the encoding and solver invariants.

The bounded `smt/` front end builds fixed-width bit-vector constraints and sends
them through the SAT encoder. Bit positions and returned source models are
least-significant-bit first. For example, a four-bit `x + 3 = 2` constraint
uses wrapping arithmetic modulo 16 and has the model `x = 15`. Widths above 8,
signed arithmetic beyond signed comparison, division, shifts, concatenation,
arrays, quantifiers, and SMT-LIB parsing are outside this API. This bit-blasting
layer should not be confused with Z3 or a general-purpose SMT solver.
`BitVec::evaluate(model)` can turn a returned source assignment back into an
unsigned value for checking a result.

Run all three electronics demonstrations with:

```sh
moon run cmd/main
```

The demo prints each selected cover, primitive gate count and a whole-package
estimate for SN74HC04/08/32, then parses and solves DIMACS SAT examples and a
four-bit QF_BV wraparound constraint. Device assumptions and full truth tables are in
[`circuits/WORKED.md`](circuits/WORKED.md); the sourced catalog is described in
[`parts/74hc-catalog.md`](parts/74hc-catalog.md).

## Implemented milestones

1. **Symbolic Boolean foundation** — canonical ROBDD operations and Tseitin CNF encoding with bounded DPLL SAT solving.
2. **Truth-table refinement and SOP cover** — explicit validation, coverage chart, essential implicants, deterministic exact selection, and BDD/SAT equivalence checks.
3. **Bench planning** — two-level gate estimates, a TI-sourced 74HC catalog, and three circuit examples with independent truth-table, BDD, and SAT checks.
4. **Bounded bit-vector reasoning** — a small QF_BV bit-blasting front end for vectors up to 8 bits, with add/subtract/multiply and signed/unsigned comparison, checked against exhaustive two-bit cases and a Z3 corpus.

## Planned work

1. Add POS presentation and tests without changing the current SOP contract.
2. Add conflict learning and measured branching heuristics only alongside independent regression oracles and a published formula set.
3. Extend the deterministic Z3 differential corpus beyond the current bounded operator and width matrix before adding more QF_BV constructs.
4. Consider division, shifts, and concatenation only with width-boundary and independent semantic tests; the current front end does not implement full SMT.
5. Add pin-level wiring guidance only for exact device variants after datasheet review; physical qualification remains out of scope until actually performed.

The examples cover a two-sensor interlock, one BCD-to-seven-segment output, and a threshold/alarm condition.

## Project shape

The root MoonBit package contains the reusable ROBDD manager in `bdd.mbt`, SAT-backed SOP verification in `sat_verify.mbt`, truth-table refinement and cover selection in `fusekite.mbt`, `coverage.mbt`, and `cover.mbt`, and structural cost primitives in `gate_cost.mbt`. The independent `sat/` package contains validated CNF, the Boolean-expression Tseitin encoder, and the DPLL solver. The `smt/` package lowers its bounded bit-vector operations to that SAT interface. The `parts/` package contains a sourced catalog; `circuits/` contains worked examples with independent truth-table vectors, literal-level SOP simulation, BDD, and SAT checks; a small executable lives under `cmd/main`.

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

The CI also runs a separate QF_BV differential check. To reproduce it locally,
install Python 3.12, install the pinned test-only solver package, then run:

```sh
python -m pip install -r tests/requirements.txt
python tests/qfbv_z3_oracle.py
```

This tooling is not a runtime dependency of the MoonBit library.

The GitHub Actions workflow pins an Ubuntu LTS image and a Node 24-compatible
checkout action, then runs formatting, check, tests, build, examples, package
validation, and the separate Z3 differential corpus on pushes to `main` and
pull requests.

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
