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

This table records verifiable commits and checks. Automated results do not
establish independent manual review, hardware correctness, or electrical
qualification.

## Reproduce the automated checks

With the MoonBit toolchain installed, run from the repository checkout:

```sh
moon fmt --check
moon check --deny-warn
moon test
moon build
moon run cmd/main
moon doc
moon package --list
```

The current test suite includes an exhaustive oracle for three-input Boolean
functions, the three circuit truth tables, arithmetic-limit checks for package
rounding, and sparse eight-input cases. Passing automated checks does not
establish electrical safety or prove that a person has reviewed the design.

## Validation scope

The recorded checks cover software formatting, type checking, tests, builds,
documentation, packaging, and the runnable examples. They do not claim an
independent line-by-line review, physical or simulator testing, electrical
qualification, or approval under a particular competition's AI-use rules.
The submitter should be able to explain the minimization and tie-break rules,
reproduce the checks, and verify the exact selected device variants before
making claims about hardware behavior.
