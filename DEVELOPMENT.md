# Development and validation

Status checked: 2026-10-16. Start with the [README](README.md) for usage,
[DESIGN.md](DESIGN.md) for contracts, and the
[full historical record](docs/development-history.md) for earlier decisions,
checks, and their original limitations.

## Direction and AI assistance

The maintainer selected the project direction and priorities, including the
downstream example, reproducible toolchain, and clearer validation records.
An AI coding assistant contributed substantially to analysis, MoonBit code,
tests, examples, documentation, CI, and automated validation. The maintainer
directs the project and is responsible for it; this record does not claim
that every line was handwritten by the maintainer.

Git author/committer fields identify the publishing account, not who typed
each change. Automated results do not establish independent human review,
personal reproduction, user feedback, datasheet review, or hardware testing.

## Current implemented scope

| Area | Implemented behavior and limits | Source / contract |
| --- | --- | --- |
| Truth tables and exact SOP/POS | One output, 1–8 inputs, don't-cares; optimize term/clause count, then literals, then deterministic patterns. POS reuses this project's complement SOP selector. | [Input](fusekite.mbt), [SOP](cover.mbt), [POS](pos.mbt), [contract](DESIGN.md#product-of-sums-selection) |
| Boolean verification | Fixed-order ROBDD with 1–32 variables; direct SOP/POS BDD and SAT checks on cared rows, with replayable SAT counterexamples. | [BDD](bdd.mbt), [SOP SAT](sat_verify.mbt), [POS verification](pos_verify.mbt) |
| SAT and bounded QF_BV | CNF/DIMACS/Tseitin and budgeted chronological DPLL; CNF up to 4,096 variables. Bit-vectors are 1–8 bits with the documented operator subset. `Unknown` remains inconclusive; no CDCL or full SMT. | [SAT](sat/solver.mbt), [QF_BV](smt/bitvec.mbt), [design](DESIGN.md) |
| Electronics planning | Direct SOP AND/OR/NOT counts and sourced 74HC package rounding. POS gate estimates, NAND/NOR mapping, wiring, and electrical qualification are absent. | [Estimator](gate_cost.mbt), [catalog](parts/74hc-catalog.md) |
| Executable use | Three SOP/POS circuits, checked SAT/QF_BV examples, and a separate consumer with its own 16-row rule and a replayed negative-case witness. | [Circuits](circuits/WORKED.md), [solver walkthrough](docs/使用指南.md#独立求解场景cnf-与四位计数器), [consumer](examples/status-indicator/README.md) |

Fusekite has no MoonBDD dependency or interoperability interface. The
[comparison](docs/MoonBDD与Fusekite范围对比.md) uses fixed source revisions,
distinguishes shared ROBDD capabilities, and separates September's baseline
from October's POS addition. It establishes neither integration nor
ecosystem-wide uniqueness. Module metadata is not proof of publication on
Mooncakes; the consumer resolves this checkout through `examples/moon.work`.

## Verified revisions and CI evidence

These completed runs were checked on 2026-10-16. Each link applies to its
recorded commit, not to later untested changes.

| Revision | Material change | Completed remote evidence |
| --- | --- | --- |
| `3371536` (September baseline) | Existing ROBDD/SAT/QF_BV, SOP, gate/package planning and circuit checks | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/36688727179) |
| `4cf0228`, `615c352`, `9d3c9df` | October POS selection, independent cost oracle, direct BDD/SAT verification, and three circuit comparisons | [`9d3c9df` failed formatting](https://github.com/Lyhdsba/Fusekite/actions/runs/38624216996); [SDK adaptation `d0abd78` passed](https://github.com/Lyhdsba/Fusekite/actions/runs/38663976603) |
| `fc6100c` | Standalone SAT model replay, budget checks, and QF_BV concrete replay in the executable | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/38684330368) |
| `6e5ae9e` | Separate downstream module and its application assertions | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/38748465937) |
| `7279bcf` | Exact SDK selector, installer/version guards, and reproduction guide | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/38826122016) |

The `7279bcf` run used Ubuntu 24.04, Moon `0.1.20261012` / moonc
`v0.10.15+943464bfa`, and the default Wasm target. Its logs confirm 66 tests,
the built-in demonstrations, the separate consumer, all 3,586 pinned-Z3
QF_BV differential cases, documentation generation, and package validation.
Earlier formatter failures remain in history; later success does not turn
those failed runs into passes.

The POS tests include all 6,561 three-input ternary specifications and all
256 three-input Boolean functions, checked by independent cost/literal
oracles and BDD/SAT paths. Another 1,296 two-input specification/completion
pairs check equivalence and replay every returned counterexample. These
finite software checks do not prove arbitrary-formula or hardware behavior.
The [archive](docs/development-history.md) retains test counts, commands,
SDK decisions, clean-install Windows/WSL results, and skipped checks by revision.

## Reproduce the checks

Install the SDK selected by [`.moonbit-version`](.moonbit-version) using the
[toolchain guide](docs/toolchain.md), then run the complete
[README check sequence](README.md#build-and-test), including the consumer
and Python 3.12 / pinned-Z3 oracle. Use the matching formatter, runtime, and
core library. Only the default Wasm target is covered; macOS and other
targets have not been validated in these records.

## Documentation verification (2026-10-16)

The current summary and complete historical record are now separate. The
archive preserves the earlier evidence and contribution statements, with
relative links adjusted for its location. This reorganization changes no
implementation, API, or past commit; deleting or moving current text cannot
erase wording already published in Git history.

On Windows with the pinned SDK, formatting, warning-free checking, all 66
tests, build, built-in examples, consumer formatting/check/run, API docs,
package listing, and all 3,586 Z3 differential cases passed again. Local
Markdown targets/anchors, archive preservation, and whitespace checks passed;
the current public files had no matches in the local-path, internal-task,
or credential-pattern scan. This local result is separate from a subsequent
remote CI run for this documentation revision.

## Next work and maintainer confirmations

The [README plan](README.md#planned-work) lists unimplemented work: device
models for POS/NAND/NOR estimates, independently checked SAT improvements,
broader QF_BV differential coverage before new operators, and device-specific
wiring guidance after datasheet review. These are plans, not delivered features.

The maintainer still needs to establish and record any personal reproduction,
independent review, external user feedback, exact-device datasheet checks,
or physical testing before claiming them. Any release also needs an explicit
publication decision and confirmation of the actual registry version.
