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

These entries describe commits and checks that exist. They are not a diary and
do not represent unrecorded manual review.

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

## Maintainer review before a competition submission

The following review has not been signed off in this record. The maintainer
should complete it personally and record only checks actually performed:

- [ ] Explain the refinement, coverage chart, exact-cover ranking, and the
  eight-input bound without relying on generated prose.
- [ ] Reproduce the build, test, and runnable example commands from a clean
  checkout, and inspect the corresponding CI run.
- [ ] Check the exact orderable SN74HC device variants and their datasheets for
  supply range, thresholds, output loading, timing, unused inputs, and the
  display-driver circuit. The included package estimate is structural only.
- [ ] If a physical or simulator test is claimed, attach its actual schematic,
  test setup, and observed results. No hardware test is claimed here.
- [ ] Check the competition's authorship and AI-assistance rules and describe
  this project's AI contribution accurately in the application.
