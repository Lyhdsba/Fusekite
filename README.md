# Fusekite

**Boolean functions in. Canonical reasoning and a small-gate estimate out.**

Fusekite is a MoonBit Boolean-reasoning and electronics-planning library. It combines a canonical ROBDD, a bounded DPLL SAT backend with Tseitin CNF encoding, exact small-table SOP and POS minimizers, and transparent 74HC gate estimates. The symbolic layers can be used independently; the electronics planner is a tested application built on those foundations.

中文使用说明见[使用指南](docs/使用指南.md)，涵盖输入规格、SOP/POS 解读、三个可运行场景与器件估算边界。

## Start with your own logic table

The main workflow is for a MoonBit developer or digital-logic learner who
has one small Boolean output to simplify and check before estimating a
direct gate implementation:

1. Fix the input order (first input is the most significant row bit), then
   pass 1–8 inputs, required 1 rows, and don't-care rows to `TruthSpec::new`.
   All other rows require 0; invalid specs return `None`.
2. Call `minimize_sop` and/or `minimize_pos`; read deterministic patterns and
   term/clause and literal counts. Check against your application rule and
   use the BDD/SAT verifiers. SAT `Unknown` is inconclusive.
3. For SOP only, call `estimate_sop_gate_cost`, then
   `@parts.estimate_74hc_packages`. These are direct structural estimates,
   without timing, pin wiring, or electrical qualification.

For a complete downstream integration, run this from the checkout root:

```sh
moon -C examples/status-indicator run .
```

The [status-indicator consumer](examples/status-indicator/README.md) is a
separate MoonBit module with its own input rule and a declared Fusekite
dependency. It checks all 16 rows, both symbolic verification paths, a
replayed counterexample to an incomplete candidate, and SOP gate/package
counts. Its workspace uses this checkout's source; it does not require or
demonstrate a published Mooncakes release. To tour the built-in circuits
and solver APIs instead, run `moon run cmd/main`.

## Capabilities and limits

Fusekite provides a reduced ordered binary decision diagram (ROBDD) manager with a fixed variable order, unique-node reduction, memoized AND/OR/XOR application, complement, evaluation, and canonical equivalence checks. Its `sat/` package validates and normalizes CNF, parses DIMACS files, encodes Boolean expression trees with shared Tseitin subexpressions, and solves with deterministic DPLL propagation under an explicit search budget. The `smt/` package adds a bounded QF_BV bit-blasting front end: unsigned bit-vectors up to 8 bits, bitwise operations, wrapping add/subtract, low-product multiplication, equality, and signed/unsigned comparison. A SAT-backed verifier can return a concrete counterexample when an SOP cover is wrong. Alongside these foundations, Fusekite validates a single-output truth table, performs deterministic Quine–McCluskey refinement and exact minimum SOP selection, estimates direct SOP gate counts, and maps those estimates to a sourced 74HC catalog.

The truth-table minimizer is intentionally bounded to one output and at most eight inputs. The ROBDD manager accepts 1–32 variables, but BDD size can grow exponentially for some functions. The CNF solver accepts up to 4,096 variables, uses two-watched-literal propagation, and caps search at a caller-selected budget. The QF_BV layer bit-blasts into Boolean expressions and CNF; this is not a native theory solver or a complete SMT implementation. DPLL remains chronological and has no conflict learning or CDCL; hard formulas can return `Unknown` when the budget expires. Fusekite is an educational planning aid, not a substitute for datasheet checks, timing analysis, or electrical safety review.

## Relationship to MoonBDD

Both projects implement ROBDDs, Boolean operations, and equivalence checks;
these shared capabilities are not unique to Fusekite. In the pinned version
documented in the [source-backed scope comparison](docs/MoonBDD与Fusekite范围对比.md),
MoonBDD also provides parsing, quantification, model counting, reordering, and
bounded finite-state reachability.

Fusekite complements that scope with a separate CNF/Tseitin/DPLL backend,
bounded QF_BV bit-blasting, and exact small-table SOP/POS minimization with
BDD/SAT verification. Its electronics workflow maps SOP results to direct
gate counts and 74HC package estimates; POS has no gate/package estimator.
These are capabilities of Fusekite as a separate MoonBit library.

Fusekite uses the ROBDD manager in `bdd.mbt` and its own `sat/` and `smt/`
packages. Its module metadata and package imports contain no MoonBDD
dependency, and it has no MoonBDD adapter, interchange format, or shared BDD
handle interface. Users call each library separately; Fusekite does not extend
MoonBDD's API. BDD node IDs are local to their owning manager.

## Example

For `F(A, B, C) = Σm(1, 3, 5, 7)`, the required rows all have `C = 1`. Fusekite produces the minimum cover `--1`, which corresponds to `F = C`.

```moonbit
let spec = TruthSpec::new(3, [1, 3, 5, 7], [])
let solution = minimize_sop(spec.unwrap())
println(solution.patterns()) // ["--1"]
```

For `F(A, B) = A OR NOT B`, the POS API returns one sum clause:

```moonbit
let spec = TruthSpec::new(2, [0, 2, 3], []).unwrap()
let solution = minimize_pos(spec)
println(solution.patterns()) // ["01"]: (A OR NOT B)
solution.evaluate(1) // Some(false)
solution.evaluate(3) // Some(true)
solution.evaluate(4) // None: out of range
```

POS patterns describe where each sum clause is **false**: `0` means a positive
literal, `1` a complemented literal, and `-` an omitted variable. An empty
clause list represents 1; one all-dash clause represents 0. The minimizer
accepts the same validated 1–8 input specs and don't-cares as SOP, ranking by
clause count, literal count, then sorted zero patterns (`- < 0 < 1`). Fully
unconstrained tables select 1. `PosSolution` is separate from `CoverSolution`;
`verify_pos_with_bdd` and `verify_pos_with_sat` check POS results directly on
cared rows, with SAT counterexamples in MSB-first order and explicit `Unknown`
on budget exhaustion. Gate estimates still accept SOP results only.
See the [POS contract](DESIGN.md#product-of-sums-selection) for exact semantics.

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

The demo prints SOP patterns and POS zero patterns, term/clause and literal
counts, and the input assumptions. It checks both forms against the independently
listed expected rows and runs their BDD/SAT equivalence checks (SAT budget:
100,000 search nodes). A mismatch or an unproved SAT result fails the demo.
It prints unspecified BCD rows separately, followed by SOP-only gate/package
estimates, DIMACS SAT examples, and a four-bit QF_BV wraparound constraint.
Device assumptions and full truth tables are in
[`circuits/WORKED.md`](circuits/WORKED.md); the sourced catalog is described in
[`parts/74hc-catalog.md`](parts/74hc-catalog.md).

The standalone solver examples also check their results: the SAT model is
replayed against all three input clauses; contradictory units must be UNSAT;
a four-clause contradiction must return `Unknown` at a one-node budget and
UNSAT at 10,000. The four-bit example decodes `x = 15` through
`BitVec::evaluate` and checks both concrete modulo-16 arithmetic and the
evaluated sum. Unexpected outcomes fail the executable and its existing CI
step. For the exact inputs, API sequence, and expected output, see the
[CNF and counter scenario walkthrough](docs/使用指南.md#独立求解场景cnf-与四位计数器).

## Three complete usage scenarios

All three scenarios run with `moon run cmd/main`. Row numbers use the first
listed input as the most significant bit; the input arrays below are the
on-set and don't-care rows passed to `TruthSpec::new` in `circuits/examples.mbt`.

| User and task | Input | Steps | Expected result |
| --- | --- | --- | --- |
| A digital-logic student compares two forms of a sensor interlock. | `door_closed, sensor_clear`; 2 inputs, on-set `[3]`, no don't-cares; active-high enable. | Run the demo; read the interlock block; decode SOP `1` as a positive literal and POS `0` as a positive literal; check all four specified rows and BDD/SAT results. | SOP `11` is `door_closed AND sensor_clear` (1 term, 2 literals). POS `-0, 0-` is `(sensor_clear) AND (door_closed)` (2 clauses, 2 literals). Both output `0,0,0,1`; the SOP estimate is one AND2 gate / one HC08 package. |
| A display-logic learner compares an active-high BCD segment with don't-cares. | `D8,D4,D2,D1`; 4 inputs, on-set `[0,2,3,5,6,7,8,9]`, don't-cares `[10,11,12,13,14,15]`; common-cathode segment `a`, valid BCD source. | Run the demo; read the BCD block; compare cost counts and the ten specified rows; inspect the separately labeled unspecified rows. | SOP `--1-, -0-0, -1-1, 1---` has 4 terms / 6 literals. POS `-100, 0001` has 2 clauses / 7 literals: `(!D4 OR D2 OR D1) AND (D8 OR D4 OR D2 OR !D1)`. Digits 1 and 4 output 0, the other valid digits 1; BDD/SAT confirm cared-row equivalence. |
| A prototype designer studies a two-of-three alarm predicate. | `sensor_A,sensor_B,sensor_C`; 3 inputs, on-set `[3,5,6,7]`, no don't-cares; equal, active-high sensor inputs. | Run the demo; read the alarm block; compare the pairwise products and sums; check all eight specified rows and the SOP package estimate. | SOP `-11, 1-1, 11-` is `BC OR AC OR AB`; POS `-00, 0-0, 00-` is `(B OR C) AND (A OR C) AND (A OR B)`. Both have 3 terms/clauses and 6 literals, assert exactly when at least two inputs are 1, and pass BDD/SAT checks. SOP uses 3 AND2 and 2 OR2 gates / one HC08 and one HC32 package. |

### Choosing SOP or POS and respecting the limits

SOP is an OR of AND terms covering required 1 rows. POS is an AND of OR clauses
excluding required 0 rows; its patterns encode where a clause is false, so their
literal polarity is opposite to SOP. Use SOP for the existing AND/OR gate and
74HC package planning path; use POS to study conjunctive conditions or compare
two-level clause/literal costs. Fewer clauses do not establish fewer gates or
packages: the BCD result uses fewer clauses but more literals. Each minimizer
optimizes its own term/clause count, then literals, then deterministic patterns;
neither optimizes arbitrary networks, delay, hazards, or physical hardware.

Both forms accept one output and 1–8 inputs. Don't-care rows may take different
values in the two results: BCD code 12 evaluates to SOP 1 and POS 0. These values
are chosen completions, not requirements. If invalid BCD can occur, specify its
outputs instead of marking it as don't-care. POS gate/package estimation and
NAND/NOR mapping are not implemented. The interlock and alarm are Boolean
teaching examples; no safety qualification or manual/hardware test is claimed.
SAT `Unknown` must remain inconclusive, even when BDD succeeds.

## Implemented milestones

1. **Symbolic Boolean foundation** — canonical ROBDD operations and Tseitin CNF encoding with bounded DPLL SAT solving.
2. **Truth-table refinement and SOP cover** — explicit validation, coverage chart, essential implicants, deterministic exact selection, and BDD/SAT equivalence checks.
3. **Bench planning** — two-level gate estimates, a TI-sourced 74HC catalog, and three circuit examples with independent truth-table, BDD, and SAT checks.
4. **Bounded bit-vector reasoning** — a small QF_BV bit-blasting front end for vectors up to 8 bits, with add/subtract/multiply and signed/unsigned comparison, checked against exhaustive two-bit cases and a Z3 corpus.
5. **Exact POS minimization** — complement-cover reuse with separate clause/result types, zero-pattern presentation, checked row evaluation, constants and don't-cares, an independent cost oracle over all 6,561 three-input ternary specs, and direct BDD/SAT verification with replayed counterexamples.

## Planned work

1. Evaluate POS and NAND/NOR gate/package estimation with explicit device models and independent checks.
2. Add conflict learning and measured branching heuristics only alongside independent regression oracles and a published formula set.
3. Extend the deterministic Z3 differential corpus beyond the current bounded operator and width matrix before adding more QF_BV constructs.
4. Consider division, shifts, and concatenation only with width-boundary and independent semantic tests; the current front end does not implement full SMT.
5. Add pin-level wiring guidance only for exact device variants after datasheet review; physical qualification remains out of scope until actually performed.

The examples cover a two-sensor interlock, one BCD-to-seven-segment output, and a threshold/alarm condition.

## Project shape

The root MoonBit package contains the reusable ROBDD manager in `bdd.mbt`, SAT-backed SOP verification in `sat_verify.mbt`, truth-table refinement and cover selection in `fusekite.mbt`, `coverage.mbt`, and `cover.mbt`, POS minimization and evaluation in `pos.mbt`, direct BDD/SAT POS verification in `pos_verify.mbt`, and structural cost primitives in `gate_cost.mbt`. The independent `sat/` package contains validated CNF, the Boolean-expression Tseitin encoder, and the DPLL solver. The `smt/` package lowers its bounded bit-vector operations to that SAT interface. The `parts/` package contains a sourced catalog; `circuits/` contains worked examples with independent truth-table vectors, literal-level SOP simulation, BDD, and SAT checks; a small executable lives under `cmd/main`.

## Build and test

CI and local reproduction use the SDK selected by [`.moonbit-version`](.moonbit-version):
`0.10.15+943464bfa`, containing Moon `0.1.20261012` / moonc
`v0.10.15+943464bfa`. The official installer selects archives by the compiler
version and commit hash, not the Moon build-system date. CI passes this exact
selector to the installer, installs the matching core library, and rejects a
compiler version mismatch. See the [toolchain installation and upgrade guide](docs/toolchain.md)
for Linux/macOS and Windows commands. An unavailable archive fails installation;
there is no fallback to `latest`.

This toolchain's formatter spells the 32-bit integer type `Int32`; older SDK
formatting results can differ. The verified version is not a compatibility claim
for every past or future SDK.

```sh
moon fmt --check
moon check --deny-warn
moon test
moon build
moon run cmd/main
moon -C examples/status-indicator fmt --check
moon -C examples/status-indicator check --deny-warn
moon -C examples/status-indicator run .
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
checkout action, then runs formatting, check, tests, build, built-in and
downstream examples, package validation, and the separate Z3 differential
corpus on pushes to `main` and pull requests.

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

Package metadata describes the source module; it does not establish that the
version is available on Mooncakes. `moon publish` is an explicit release action.

## License

Apache-2.0. See [LICENSE](LICENSE).
