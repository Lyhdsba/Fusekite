# Development and validation

The [2026-10-26 final acceptance audit](docs/acceptance-stage6.md) consolidates
the technical evidence and remaining participant confirmations. Technical
readiness does not establish an organizer decision or personal understanding.

The [2026-10-25 GitHub and acceptance cross-check](docs/acceptance-stage3.md)
maps the October site's six criteria and the supplied nine requirements to
source, tests, substantive October commits, and exact remote CI evidence.
The [2026-10-26 stage 5 check](docs/acceptance-stage5.md) subsequently installed
`Lyhdsba/fusekite@0.2.0` from Mooncakes in a clean independent consumer and ran
its public API assertions. A separate manual workflow reproduces this registry
path; the existing local-source consumer CI remains in place.

The [2026-10-25 stage 2 acceptance audit](docs/acceptance-stage2.md) records the
test/example/CI review, the reproduced QF_BV corpus-integrity gap and fix, new
SOP verifier regressions, reproduction commands, and uncovered boundaries.

Status checked: 2026-10-26. Start with the [README](README.md) for usage,
[DESIGN.md](DESIGN.md) for contracts, and the
[full historical record](docs/development-history.md) for earlier decisions,
checks, and their original limitations.

## Direction and AI assistance

The maintainer selected the combination-logic minimizer topic, electronics
focus, single-output scope, and project priorities.
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
| Electronics planning | Direct SOP and POS AND/OR/NOT counts with sourced 74HC package rounding. NAND/NOR mapping, wiring, and electrical qualification remain absent. | [Estimators](gate_cost.mbt), [catalog](parts/74hc-catalog.md) |
| Executable use | Three SOP/POS circuits, checked SAT/QF_BV examples, and a separate consumer with its own 16-row rule and a replayed negative-case witness. | [Circuits](circuits/WORKED.md), [solver walkthrough](docs/使用指南.md#独立求解场景cnf-与四位计数器), [consumer](examples/status-indicator/README.md) |

Fusekite has no MoonBDD dependency or interoperability interface. The
[comparison](docs/MoonBDD与Fusekite范围对比.md) uses fixed source revisions,
distinguishes shared ROBDD capabilities, and separates September's baseline
from October's POS minimizer and direct POS gate estimate. It establishes
neither integration nor ecosystem-wide uniqueness. The local-source consumer
resolves this checkout through `examples/moon.work`; the separate
[registry consumer](docs/acceptance-stage5.md) verifies the published `0.2.0`.

## Verified revisions and CI evidence

The earlier runs below were checked on 2026-10-16; the `426836a` run was
checked on 2026-10-25. Each link applies to its recorded commit, not to later
untested changes.

| Revision | Material change | Completed remote evidence |
| --- | --- | --- |
| `3371536` (September baseline) | Existing ROBDD/SAT/QF_BV, SOP, gate/package planning and circuit checks | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/36688727179) |
| `4cf0228`, `615c352`, `9d3c9df` | October POS selection, independent cost oracle, direct BDD/SAT verification, and three circuit comparisons | [`9d3c9df` failed formatting](https://github.com/Lyhdsba/Fusekite/actions/runs/38624216996); [SDK adaptation `d0abd78` passed](https://github.com/Lyhdsba/Fusekite/actions/runs/38663976603) |
| `fc6100c` | Standalone SAT model replay, budget checks, and QF_BV concrete replay in the executable | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/38684330368) |
| `6e5ae9e` | Separate downstream module and its application assertions | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/38748465937) |
| `7279bcf` | Exact SDK selector, installer/version guards, and reproduction guide | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/38826122016) |
| `426836a` | SOP verifier regressions and complete QF_BV corpus/model evidence gates; 70 MoonBit tests, 10 Python tests, and 3,586 Z3 cases | [Successful CI](https://github.com/Lyhdsba/Fusekite/actions/runs/40146045134) |

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

At `3254d47`, on Windows with the pinned SDK, formatting, warning-free checking,
all 66 tests, build, built-in examples, consumer formatting/check/run, API docs,
package listing, and all 3,586 Z3 differential cases passed again. Local
Markdown targets/anchors and whitespace checks also passed. These local
results apply to that revision and do not establish remote CI success for
later changes.

The subsequent README and API-boundary documentation also passed formatting,
warning-free checking, all 66 tests, build, the built-in examples, consumer
formatting/check/run, API documentation generation, and package listing on
Windows with the same pinned SDK. The examples reproduced the documented
SOP/POS patterns and 4/10/8 cared-row checks; the consumer checked 16 rows and
replayed its row-10 counterexample. The separate Z3 differential corpus was
not rerun for this documentation-only change; the implementation and corpus
are unchanged. Earlier Z3 results remain tied to their recorded revisions.

## Next work and maintainer confirmations

The [README plan](README.md#planned-work) lists unimplemented work: device
models for NAND/NOR estimates, independently checked SAT improvements,
broader QF_BV differential coverage before new operators, and device-specific
wiring guidance after datasheet review. These are plans, not delivered features.

The maintainer still needs to personally confirm understanding of the design,
AI-assisted changes, and fulfillment of the formally approved proposal.
Personal reproduction, independent review, external user feedback, exact-device
datasheet checks, or physical testing must be established before being claimed.
Version `0.2.0` is published and verified by the registry consumer; future
releases require their own publication and validation evidence.

## POS gate-planning verification (2026-10-16)

On the pinned Windows toolchain, the current tree passed formatting, warning-
free checking, all 68 tests, build, the three worked circuits, the independent
consumer's formatting/check/run, API documentation, and package listing. The
QF_BV differential corpus also passed all 3,586 Z3 cases. The circuit outputs
now expose separate direct SOP and POS gate/package counts. These are local
results for this tree; remote CI and physical hardware checks are not claimed.

## October acceptance and release checkpoint (2026-10-24)

At `f48a75d`, the README includes the Mooncakes installation command and the
visible text corruption in the MoonBDD scope note is corrected. The new
`.moonignore` keeps the repository's cache/build exclusions and excludes the
root-level submission draft and `output/` artifacts from release archives.
`moon package --list` was checked with those local files present and omitted
both paths.

On Windows with the SDK pinned by [`.moonbit-version`](.moonbit-version),
formatting, warning-free type checking, all 68 tests, build, the three worked
circuits, consumer format/check/run, API documentation, and package listing
passed. The pinned Z3 oracle passed all 3,586 QF_BV cases. The GitHub Actions
[run for `f48a75d`](https://github.com/Lyhdsba/Fusekite/actions/runs/40106648234)
also passed.

The repository is public, the October history contains substantive feature,
test, example, and documentation commits, and the implemented project scope
is described above. At that checkpoint the module was not yet present in the
Mooncakes registry; publication of `Lyhdsba/fusekite` and a clean downstream
install remained outstanding. The later stage 5 evidence is linked above.
