# Development and review record

## Who decided what

The project maintainer chose the combination-logic minimizer topic, the
electronics focus, the single-output scope, and the requested milestones and
acceptance checks. An AI coding assistant contributed substantially to the
MoonBit implementation, tests, worked examples, documentation, and CI changes.
The maintainer directed the work and is responsible for the submitted project;
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
| `62e6c5c` | Disclosed substantial AI assistance and recorded owner-review items | The review checklist remains open; no manual or hardware review is claimed. |
| `c963a0a` | Pinned CI runner and Node-compatible checkout action | [Remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36376743147). |
| `6f60cc2` | Added the competition proposal with AI contribution disclosure | Removed personal contact details from the public copy; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36399790990). |
| `7427929` | Snapshotted caller-owned truth-table arrays during validation | Added a regression test; 23 tests passed and [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36408528637). |
| `0dd93e0` | Hid validated row arrays and exposed defensive-copy accessors | Added a cross-package mutation regression; 23 tests and local format, check, build, demo, docs, and package checks passed before push. |
| `a349dbc` | Added canonical ROBDD operations and BDD-based SOP verification | 28 tests passed; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36678108262). |
| `84eea16` | Added CNF normalization, Tseitin encoding, DIMACS parsing, and bounded DPLL | 35 tests in that revision; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36679540370). |
| `d1e88da` | Added two-watched propagation, SAT counterexample verification, and runnable DIMACS examples | 41 tests passed locally; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36680024543). |
| `8cee460` | Corrected the recorded test count for the SAT milestone | [Remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36680140854). |
| `6b898bf` | Corrected the proposal's description of watched-literal propagation | 41 tests passed; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36683796025). |
| `649148b` | Added bounded QF_BV bit-vector operations lowered to the SAT backend | 48 tests passed; exhaustive two-bit operator checks; [remote CI passed](https://github.com/Lyhdsba/Fusekite/actions/runs/36685216612). |

This table records verifiable commits and checks. Automated results do not
establish independent manual review, hardware correctness, or electrical
qualification.

## Reproduce the automated checks

With the MoonBit toolchain and Python 3.12 installed, run from the repository checkout:

```sh
moon fmt --check
moon check --deny-warn
moon test
moon build
moon run cmd/main
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

The separate Python check emits 2,550 deterministic QF_BV constraints across
widths 1 through 8 and compares SAT status with the pinned Z3 reference. For
satisfiable cases it checks the returned source assignment against concrete
unsigned arithmetic and asks Z3 to validate the same model.

## Validation scope

The recorded checks cover software formatting, type checking, tests, builds,
documentation, packaging, SAT/BDD/QF_BV software oracles, a bounded QF_BV
differential corpus against Z3, and the runnable examples. They do not claim an
independent line-by-line review, differential coverage of arbitrary SMT
formulas, physical or simulator testing, electrical qualification, or approval
under a particular competition's AI-use rules.
The submitter should be able to explain the minimization and tie-break rules,
reproduce the checks, and verify the exact selected device variants before
making claims about hardware behavior.
