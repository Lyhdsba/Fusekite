# October acceptance stage 2: tests, examples, and CI

Audit date: 2026-10-25. Scope: the public `Lyhdsba/Fusekite` repository,
module `Lyhdsba/fusekite`, tests and runnable examples, CI check/build/test
gates, and reproduction. The starting local and remote `main` both pointed
to `e6614cb38e0d88c8eb56de08aa5a842258b3e9a7`; its
[completed CI run](https://github.com/Lyhdsba/Fusekite/actions/runs/40106786617)
was successful. This audit does not publish a Mooncakes release.

## Coverage reviewed and exercised

| Core path | Executed evidence | Boundary |
| --- | --- | --- |
| Truth specification and SOP cover | [Public API tests](../fusekite_test.mbt) reject invalid rows/dimensions, check defensive copies, don't-cares, constants, and eight-input endpoints. [Cover tests](../cover.mbt) check all 256 three-input Boolean functions against a prime-subset cost oracle. | The SOP cost oracle shares the implementation's prime generation; it is not an independent proof of every prime. Four through eight inputs are not exhaustively enumerated. |
| SOP BDD/SAT verification | [Verifier tests](../sat_verify.mbt) now compare all 81 two-input ternary specs with all 16 candidate functions (1,296 pairs), independently determine cared-row equivalence, and replay every SAT witness in MSB-first order. A majority-function miter must return `Unknown` at budget 1 and `Equivalent` at 100,000. Existing tests reject a nonempty cover with the wrong width. | Budgets are search-node limits, not wall-clock guarantees. `Unknown` is never a proof. |
| POS minimization and verification | [POS tests](../pos_test.mbt) cover all 6,561 three-input ternary specs using a separate literal-choice/dynamic-programming cost oracle, all 256 Boolean functions, 1,296 two-input spec/candidate pairs with cared-row witness replay, constants and width boundaries, tie-breaks, and budget exhaustion. | Finite enumerations do not establish arbitrary-width or arbitrary-network optimality. POS reuses complement SOP selection. |
| ROBDD, CNF/DIMACS, Tseitin, DPLL | [BDD tests](../bdd.mbt) check canonicity, operations, validation, parity, and two-variable CNF agreement. [SAT tests](../sat/solver.mbt) check normalization, parser failures, propagation, backtracking, exhaustive two-variable and sampled three-variable CNFs, concrete models, Tseitin truth tables/sharing, and budget exhaustion. | No CDCL, general SAT proof certificate, exhaustive large-formula testing, or broad performance claim. |
| Bounded QF_BV | [Bit-vector tests](../smt/bitvec.mbt) check constructors, width mismatches, budget/invalid results, wraparound and exhaustive two-bit arithmetic. The [corpus generator](../cmd/qf_bv_corpus/main.mbt) and [pinned-Z3 oracle](../tests/qfbv_z3_oracle.py) compare all 3,586 expected cases and replay SAT models concretely and in Z3. | Widths 1–8; seven value operators (`add`, `sub`, `mul`, `and`, `or`, `xor`, `not`) over every target with unsigned `x < y`, plus signed comparison true/false at each width. This is not exhaustive operand/formula coverage or a full SMT implementation. |
| Direct gate and package planning | [Gate tests](../gate_cost.mbt), [catalog tests](../parts/catalog.mbt), and [worked circuits](../circuits/examples.mbt) check direct SOP/POS trees, shared inversions, package rounding and the BCD POS estimate. | No NAND/NOR network search, timing, hazards, pin wiring, or electrical/hardware qualification. |

## Actual gaps fixed

The old QF_BV script checked only the number of output rows. During this audit,
the actual 3,586-row generator output was captured, and its last row was
replaced with its first row. The resulting corpus contained only 3,585 distinct
keys, yet the original script returned 0 and printed a passing 3,586-case
result. It also lacked an explicit SAT-model range check and an exact outcome
allowlist, allowing bit-vector coercion or an unexpected non-SAT token to
weaken validation.

The oracle now validates the complete expected `(operator, width, target)` set,
requires each key once, accepts only `SAT` or `UNSAT`, checks model bounds and
UNSAT placeholders, and rejects missing/malformed cases before Z3 comparison.
The new [10 Python regression tests](../tests/test_qfbv_z3_oracle.py) inject
duplicates replacing missing cases, truncated/empty output, unexpected keys,
undecided/misspelled outcomes, malformed fields, wrapped/negative models, and
generator failures. They also verify order-independent complete input and
preservation of valid SAT payloads. These transport fixtures do not themselves
claim semantic correctness; the real corpus still runs separately against Z3.

SOP also lacked the POS path's exhaustive two-input verifier comparisons and
an explicit budget-exhaustion regression. Two tests now cover those contracts
without changing the solver or minimizer implementation.

## Runnable examples

Both existing entry points were actually run; no duplicate example was needed.

- `moon run cmd/main` checks three circuits against independent expected
  truth rows (4 interlock, 10 cared BCD, 8 majority), SOP/POS BDD/SAT checks,
  direct gate/package results, SAT model replay, an UNSAT contradiction,
  explicit budget exhaustion, and the four-bit `x + 3 = 2` model `x = 15`.
- `moon -C examples/status-indicator run .` runs the
  [separate consumer](../examples/status-indicator/README.md), checks all 16
  application-rule rows through public APIs, and rejects an incomplete
  candidate by replaying SAT witness row 10. Its own `moon.mod` and package
  imports use the local library through `examples/moon.work`. This demonstrates
  source consumption, not installation from a published registry release.

The commands fail on assertion errors; CI runs both executables, rather than
checking only printed output or whether they compile.

## CI and reproduction

[The workflow](../.github/workflows/ci.yml) runs on pushes and pull requests
to `main`, plus manual dispatch, on Ubuntu 24.04 with a 15-minute job limit and
read-only repository permissions. It installs the SDK selected by
[`.moonbit-version`](../.moonbit-version), rejects a compiler mismatch, uses
Python 3.12 and `z3-solver==5.1.0.0`, then gates on:

1. Root formatting and warning-free checking.
2. MoonBit tests and build.
3. Built-in examples and downstream consumer formatting/check/run.
4. Python evidence-gate regressions (added in this stage), followed by the
   actual Z3 differential corpus.
5. API documentation and package listing.

A nonzero command fails the job; no `continue-on-error` masks these checks.
This describes workflow failure gates. Required branch-protection/merge rules
were not audited or changed and are not claimed.

Use the exact SDK installation instructions in the
[toolchain guide](toolchain.md), then run the complete
[README command sequence](../README.md#build-and-test), including Python
regressions and Z3. For an isolated oracle environment on Windows, from the
repository root with Python 3.12 available:

```powershell
python -m venv "$env:TEMP\fusekite-oracle"
& "$env:TEMP\fusekite-oracle\Scripts\python.exe" -m pip install -r tests/requirements.txt
& "$env:TEMP\fusekite-oracle\Scripts\python.exe" -B -m unittest discover -s tests -p 'test_*.py' -v
& "$env:TEMP\fusekite-oracle\Scripts\python.exe" -B tests/qfbv_z3_oracle.py
```

Local verification for this stage used Windows, the default Wasm target, Moon
`0.1.20261012`, moonc `v0.10.15+943464bfa`, Python `3.12.14`, and the pinned Z3
package in a fresh temporary virtual environment. Formatting, warning-free
checking, all **70 MoonBit tests**, build, both executable entry points,
consumer format/check, API docs, package listing, all **10 Python tests**, and
all **3,586 Z3 cases** passed. The local submission draft and `output/` were
left untouched and remained absent from the package listing.

These local results do not claim a new remote CI success. A successful Actions
run must be matched to its exact pushed commit; the starting revision's run
above cannot certify this stage's later edits. This audit makes no claims of
fresh SDK installation, macOS/other-target testing, registry publication,
independent human review, or hardware validation.
