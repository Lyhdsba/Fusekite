# Historical development and validation record

This archive preserves the development record through commit
[`7279bcf`](https://github.com/Lyhdsba/Fusekite/commit/7279bcfaeb8e024631d938377fb1ee3e4044890a).
Results, test counts, missing features, and phrases such as "latest completed
remote run" below refer to the revision described in each entry. They are
historical observations, not the current project status. Commands were run
from the checkout root unless stated otherwise.

For current capabilities, CI evidence, reproduction, and plans, start with
[the current development record](../DEVELOPMENT.md). Entries below record
implementation changes, automated results, and AI contributions by revision.

## Who decided what

The project maintainer chose the combination-logic minimizer topic, the
electronics focus, the single-output scope, and the requested milestones and
acceptance checks. An AI coding assistant contributed substantially to the
MoonBit implementation, tests, worked examples, documentation, and CI changes.
The maintainer directed the work and is responsible for the project;
this record does not claim that every line was handwritten by the maintainer.

Git author and committer fields identify the repository account used for
publishing. They are not independent evidence of who typed each change. The
commit history and this record should be read together.

## Versioned implementation milestones

| Commit | Change | Recorded validation |
| --- | --- | --- |
| `37f6189` | Bounded truth-table model and prime-implicant refinement | Initial core tests and checks were run during implementation. |
| `515d11a` | Exact SOP cover selection and exhaustive three-input subset oracle | The oracle covers all 256 three-input Boolean functions. |
| `db8f213` | Two-level SOP gate-count primitives | Gate-count and package-rounding tests added. |
| `5ee1e14` | Sourced 74HC package catalog | Catalog channel counts and package rounding tested. |
| `7e8c64b` | Three electronics examples | Independent expected-output vectors added for each example. |
| `39c7f60` | CI, runnable examples, and Mooncakes metadata | The first remote CI run exposed newer-compiler warnings in black-box tests. |
| `22e87cd` | Qualified black-box test references for current MoonBit | Remote CI passed after this fix. |
| `7e3a72a` | Integer-overflow guard and sparse eight-input boundary cases | 22 tests passed locally and [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36376524489). |
| `62e6c5c` | Disclosed substantial AI assistance and recorded owner-review items | This disclosure does not establish manual review or hardware validation. |
| `c963a0a` | Pinned CI runner and Node-compatible checkout action | [Remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36376743147). |
| `6f60cc2` | Added the competition proposal with AI contribution disclosure | [Remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36399790990). |
| `7427929` | Snapshotted caller-owned truth-table arrays during validation | Added a regression test; 23 tests passed and [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36408528637). |
| `0dd93e0` | Hid validated row arrays and exposed defensive-copy accessors | Added a cross-package mutation regression; 23 tests and local format, check, build, demo, docs, and package checks passed before push. |
| `a349dbc` | Added canonical ROBDD operations and BDD-based SOP verification | 28 tests passed; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36678108262). |
| `84eea16` | Added CNF normalization, Tseitin encoding, DIMACS parsing, and bounded DPLL | 35 tests in that revision; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36679540370). |
| `d1e88da` | Added two-watched propagation, SAT counterexample verification, and runnable DIMACS examples | 41 tests passed locally; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36680024543). |
| `8cee460` | Corrected the recorded test count for the SAT milestone | [Remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36680140854). |
| `6b898bf` | Corrected the proposal's description of watched-literal propagation | 41 tests passed; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36683796025). |
| `649148b` | Added bounded QF_BV bit-vector operations lowered to the SAT backend | 48 tests passed; exhaustive two-bit operator checks; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36685216612). |
| `9c5016f` | Added a pinned Z3 differential corpus and made it part of CI | 2,550 bounded cases passed locally and in [remote CI](https://github.com/Lyhdsba/Fusekite/actions/runs/36685869093). |
| `e26971f` | Added wrapping subtraction, low multiplication, signed comparison, and structural Tseitin sharing | Expanded the pinned-Z3 corpus to 3,586 cases; formatting, type checks, and all 51 tests passed locally. |
| `82ed08a` | Added independent expected-vector validation and literal-level SOP simulation for all worked circuits | Every specified example row passed simulation, BDD, and SAT checks; build, runnable examples, docs, and package listing passed locally. |

This table records verifiable commits and checks. Automated results do not
establish independent manual review, hardware correctness, or electrical
qualification.

## October POS increment (2026-10-15)

Added `minimize_pos`, private-backed `PosClause`/`PosSolution` types, falsifying
patterns, defensive-copy clause accessors, and range-checked row evaluation.
The implementation reuses the existing complement SOP cover selector through
De Morgan's law; it preserves the SOP contract. Constants, don't-cares,
fully unconstrained specs, and the deterministic cost/tie-break order are
documented in the [design contract](../DESIGN.md#product-of-sums-selection).

The AI coding assistant substantially contributed to this implementation,
the eight new black-box tests, the independent literal-enumeration/subset-DP
cost oracle, and documentation. All 256 three-input Boolean functions and all
81 two-input ternary specs were checked for minimum clause/literal cost and
cared-row semantics, including separate evaluation of the exported patterns.
Additional tests cover constants at widths 1–8, don't-care expansion, empty
products/sums, one-input polarity, eight-input endpoints/MSB, invalid rows,
determinism, and defensive copies.

Local Moon `0.1.20260827` / moonc `v0.10.11+6ff76a5f9` checks passed:
`moon fmt --check`, `moon check --deny-warn`, all 59 tests, `moon build`,
`moon run cmd/main`, `moon doc`, and `moon package --list`. The pinned Z3
`5.1.0.0` differential check also passed all 3,586 existing QF_BV cases.
These are automated software results; no human review or manual/hardware
testing is claimed. At this revision, POS circuit demonstrations were absent;
the next verification increment below adds dedicated POS BDD/SAT checks.

The preceding main revision `1dbdb5b` failed its [remote format check](https://github.com/Lyhdsba/Fusekite/actions/runs/38590700258):
the automatically installed Moon `0.1.20261012` formatter rewrites `Int` as
`Int32`, unlike the local toolchain. This is a pre-existing toolchain drift;
the local results above do not establish remote CI success. This POS
increment still used the older local SDK.

## POS independent verification increment (2026-10-15)

Added `verify_pos_with_bdd` and `verify_pos_with_sat`. Each constructs literal
OR clauses and their AND directly from POS patterns, compares against the
cared truth-table rows, and uses the existing independent symbolic backend.
Neither calls the minimizer or POS row evaluator. Width mismatches, including
empty products of the wrong width, are rejected. SAT returns MSB-first source
inputs for a mismatch and preserves `Unknown` on exhausted search.

Six additional black-box tests and the expanded three-input Boolean test ran:

- All 6,561 three-input ternary specs passed the independent clause-enumeration
  and subset-DP minimum-cost oracle, independent literal evaluation, and both
  BDD/SAT equivalence checks. All 256 three-input Boolean functions also passed
  both symbolic checks.
- All 81 two-input ternary specs were compared with all 16 Boolean completions
  (1,296 pairs). Independent row enumeration agreed with both symbolic results;
  every SAT counterexample was replayed through literal semantics and confirmed
  to lie outside the don't-care set.
- Constants and fully unconstrained specs passed symbolic checks at every width
  1–8. Further cases checked eight-input MSB-first witnesses, width rejection,
  and a one-search-node budget returning `Unknown` before a larger-budget proof.

Local Moon `0.1.20260827` / moonc `v0.10.11+6ff76a5f9` checks passed:
`moon fmt --check`, `moon check --deny-warn`, all 65 tests, `moon build`,
`moon run cmd/main`, `moon doc`, and `moon package --list`; `git diff --check`
also passed. The separate pinned-Z3 `5.1.0.0` differential corpus passed all
3,586 QF_BV cases again. These finite software checks do not establish an unbounded
proof or human/hardware validation. The AI coding assistant substantially
contributed to the verification APIs, tests, and documentation. The preceding
remote CI toolchain-drift failure remains distinct from these local results.

## POS usage scenarios and public disclosure (2026-10-15)

The executable now compares SOP/POS for the interlock, BCD segment a, and
two-of-three alarm. It prints assumptions, patterns, and clause/literal costs;
checks both results against the independent expected vectors (4, 10, and 8
cared rows); and requires both BDD and SAT proofs. SAT uses 100,000 search nodes,
and any counterexample, invalid input, or `Unknown` fails the demo. Unspecified
BCD rows are printed separately; code 12 has SOP 1 and POS 0. The added circuit
test pins all three POS results and explicitly checks that allowed difference.
Gate/package estimates remain SOP-only; POS and NAND/NOR mapping are absent.

README and the worked-circuit documentation give the user, input, steps, and
expected result for each scenario. They distinguish two-level term/clause costs
from hardware cost. The AI coding assistant substantially contributed to this
increment's code, automated checks, scenarios, and documentation. The recorded
checks do not establish personal reproduction, independent line-by-line review,
datasheet review, or hardware testing.

Local Moon `0.1.20260827` / moonc `v0.10.11+6ff76a5f9` checks passed:
`moon fmt --check`, `moon check --deny-warn`, all 66 tests, `moon build`,
`moon run cmd/main`, `moon doc`, `moon package --list`, and `git diff --check`.
The QF_BV code and corpus were unchanged and the separate Z3 check was not
rerun for this increment; prior results above remain historical evidence.
At preparation time, the latest completed remote run was still the failed
`1dbdb5b` format check linked above. Local checks do not establish remote CI
success or resolve that toolchain drift.

## Reproduce the automated checks

Install the SDK selected by `.moonbit-version` using the
[toolchain guide](../docs/toolchain.md), plus Python 3.12, then run from the
repository checkout:

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
python -m pip install -r tests/requirements.txt
python tests/qfbv_z3_oracle.py
```

At `649148b`, the MoonBit suite contains 48 tests, including an exhaustive
oracle for three-input Boolean functions, every two-variable CNF paired with a
truth-assignment oracle and the ROBDD backend, 1,024 sampled three-variable
CNFs checked against exhaustive assignments, DIMACS parser boundary cases,
Tseitin truth-table checks, SAT counterexample checks for all worked circuits,
arithmetic-limit checks for package rounding, sparse eight-input cases, and
every two-bit operand pair checked against the bounded bit-vector operators.
Passing automated checks does not establish electrical safety or prove that a
person has reviewed the design.

The separate Python check emits 3,586 deterministic QF_BV constraints across
widths 1 through 8 and compares SAT status with the pinned Z3 reference. For
satisfiable cases it checks the returned source assignment against concrete
unsigned arithmetic and asks Z3 to validate the same model.

## Validation scope

The recorded checks cover software formatting, type checking, tests, builds,
documentation, packaging, SAT/BDD/QF_BV software oracles, a bounded QF_BV
differential corpus against Z3, literal-level SOP simulation, and the runnable
examples. They do not claim an independent line-by-line review, differential
coverage of arbitrary SMT formulas, external HDL simulation, physical testing,
electrical qualification. Hardware use still requires verification against the
exact selected device variants and their datasheets; software estimates do not
establish electrical behavior.

## SDK formatting compatibility (2026-10-15)

The source-backed MoonBDD comparison separates the fixed September baseline
from the October POS increment. The comparison describes current implemented
scope; it does not establish code reuse or integration.

The latest completed remote run at preparation time, [`9d3c9df`](https://github.com/Lyhdsba/Fusekite/actions/runs/38624216996),
failed formatting with Moon `0.1.20261012`. This audit reproduced the failure
using the official Windows SDK, whose binary archive SHA-256 matched the
vendor's published checksum. The SDK was installed separately from the older
local SDK. Its formatter rewrote the `Int` alias as `Int32` and wrapped three
long declarations; the resulting source changes add no algorithm or feature.
README and the numeric design contract now identify the verified toolchain
and integer spelling. At that revision, CI still installed stable and reported
its version; subsequent stable updates could require another compatibility check.

With Moon `0.1.20261012` / moonc `v0.10.15+943464bfa`, the following passed:
`moon fmt --check`, `moon check --deny-warn`, all 66 tests, `moon build`,
`moon run cmd/main`, `moon doc`, `moon package --list`, and `git diff --check`.
The executable checked 4, 10, and 8 cared rows and both BDD/SAT paths for each
SOP/POS scenario. Python 3.12 and the pinned Z3 `5.1.0.0` differential check
passed all 3,586 QF_BV cases again for this SDK adaptation.
Local success is distinct from the subsequent remote run for this change.

The AI coding assistant substantially assisted the SDK compatibility work,
automated verification, and documentation. These results do not establish
human review, personal reproduction, user feedback, or hardware testing.

## Chinese usage documentation (2026-10-15)

The [Chinese usage guide](../docs/使用指南.md) brings together the implemented API
entry points, truth-table input rules, SOP/POS pattern polarity, three runnable
circuits, SAT outcome interpretation, and the SOP-only device estimate model.
The MoonBDD comparison remains tied to fixed
source revisions rather than asserting the current state of an upstream branch.
No algorithm or public API changed in this documentation revision.

With Moon `0.1.20261012` / moonc `v0.10.15+943464bfa`, local formatting,
warning-free type checking, all 66 tests, the runnable examples, API documentation
generation, and package listing passed. The examples reproduced the documented
patterns, costs, and 4/10/8 cared-row checks with BDD/SAT equivalence. The separate
Z3 corpus was not rerun for this documentation revision; earlier runs above are
historical results. Local checks do not establish a subsequent remote CI result.

The AI coding assistant substantially contributed to the guide, related
documentation edits, source inspection, and automated validation. No independent
human review, user feedback, or hardware testing is claimed.

## Executable standalone solver scenarios (2026-10-15)

The SAT and QF_BV sections of `moon run cmd/main` now require their expected
outcomes rather than only printing unexpected results. The SAT example replays
the returned model through `CnfFormula::accepts`; the QF_BV example uses
`BitVec::evaluate` for both the variable and sum and independently checks the
integer modulo-16 equation. A four-clause two-variable contradiction demonstrates
`Unknown` with exactly one search node, then UNSAT with a 10,000-node budget.
The Chinese usage guide records each user's task, exact inputs, API sequence,
model interpretation, and observable output. No solver algorithm or public API
changed; the existing CI example command exercises the added runtime checks.

Using Moon `0.1.20261012` / moonc `v0.10.15+943464bfa`, these local commands
passed: `moon fmt --check`, `moon check --deny-warn`, `moon test` (66 passed,
0 failed), `moon build`, `moon run cmd/main`, `moon doc`, `moon package --list`,
and `git diff --check`. The run printed SAT model `1, 0, 1` and confirmed all
three input clauses; contradictory units returned UNSAT; the four-clause case
returned the expected budget-dependent results. The four-bit case printed
`x = 15` and confirmed `(15 + 3) % 16 = 2`. The three circuit scenarios also
passed their existing 4/10/8 cared-row and SOP/POS BDD/SAT checks.

The separate Z3 corpus was not rerun for this example-only implementation
change; prior corpus results remain historical evidence. These local results
do not establish a subsequent remote CI result. The AI coding assistant
substantially contributed to the executable checks, scenario documentation,
and automated validation; no human reproduction, user feedback, or hardware
testing is claimed.

## Downstream consumer and entry workflow (2026-10-15)

An AI coding assistant substantially contributed to the downstream consumer,
its documentation, and automated validation.

`examples/status-indicator` is a separate MoonBit
module declaring a Fusekite dependency; `examples/moon.work` resolves it from
the checkout rather than assuming a Mooncakes publication. The consumer's
own four-input build/review indicator rule differs from the built-in circuits.
It checks all 16 rows against the application predicate, independently
interprets SOP patterns, checks POS evaluation, and requires BDD/SAT
equivalence for both forms. An incomplete candidate must be rejected and its
SAT witness at row 10 is replayed. Direct SOP gates and package counts are
asserted. CI now checks and runs the separate consumer.

With Moon `0.1.20261012` / moonc `v0.10.15+943464bfa`, local formatting,
warning-free checking, all 66 library tests, build, the built-in examples,
API documentation, package listing, and `git diff --check` passed. The
consumer's formatting, warning-free check, and executable assertions also
passed. A copy of the consumer also checked and ran in a workspace outside
the repository. Omitting row 10 from that copy's input reached and failed
the result assertion; restoring the source passed again on the default Wasm
target. The SAT/QF_BV implementation and corpus were unchanged; the separate
Z3 differential corpus was not rerun. These results do not claim manual
review, user feedback, physical testing, or a subsequent remote CI result.

## Pinned toolchain and clean-install validation (2026-10-16)

An AI coding assistant substantially contributed to the CI toolchain pin,
installation guide, and automated validation. No human review, manual
reproduction, user feedback, or hardware testing is claimed.

CI previously invoked the official installer without a version, implicitly
selecting `latest`. It now reads `.moonbit-version`, passes the exact compiler
release `0.10.15+943464bfa` to the installer, and checks the installed compiler
identity. This is the existing validated SDK (Moon `0.1.20261012`), not a newly
chosen or inferred compatibility version. The official Linux and Windows
binary archives and matching core archives were available under this selector.
The Windows archive checksum published at that version also matched the
previously validated archive. The [toolchain guide](../docs/toolchain.md) records
installation, clean validation, and the upgrade procedure; unavailable archives
must fail rather than silently selecting another SDK.

Fresh official installations and source copies passed formatting,
warning-free checking, all 66 tests, build, built-in circuit/solver examples,
the independent consumer's formatting/check/run assertions, API documentation,
and package listing on Windows and Ubuntu 26.04 under WSL. Windows Python
3.12.14 with pinned Z3 `5.1.0.0` passed all 3,586 differential cases. Workflow
YAML parsing and Bash syntax checks passed. Executing the workflow guards
rejected empty, `latest`, and Moon-date selectors before downloading, accepted
the pinned compiler, and rejected the older installed compiler.

These checks cover the default Wasm target. macOS and other targets were not
tested. The local Linux checks used Ubuntu 26.04 WSL, distinct from CI's
Ubuntu 24.04 runner; no new remote CI result is claimed by this local record.
