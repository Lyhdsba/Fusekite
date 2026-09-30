# Design contract

## Input model

- A function has one output and 1–8 input bits.
- Row numbers are unsigned binary indices. The first input is the most significant bit.
- The on-set and don't-care set are unique, disjoint, and within the truth-table range.
- Rows omitted from both sets are required zeroes.
- `TruthSpec::new` copies both row arrays after validation. The stored arrays stay private; public accessors return copies so later caller mutations cannot invalidate the specification.

## ROBDD manager

- `BddManager` fixes a variable order at construction and supports 1–32 variables. Variable index 0 is the first decision level.
- Node IDs 0 and 1 are the false and true terminals. Non-terminal IDs are local to one manager and must not be mixed with IDs from another manager.
- `make_node` applies the reduction rule `low == high => low` and linearly searches the unique table for an existing `(variable, low, high)` triple.
- AND, OR, and XOR use Shannon expansion in the fixed variable order. The apply cache memoizes canonicalized operand pairs, and complement results are memoized by node; all exposed operations check IDs before using them.
- Equivalent functions built in the same manager reduce to the same node ID. `reachable_node_count` reports the final graph size; `node_count` reports all non-terminal nodes allocated during the manager lifetime, including intermediate nodes.
- ROBDDs can be exponential in the worst case and the current unique/apply tables use linear lookup. This is a foundational symbolic Boolean package, not a SAT, BDD-optimized, or SMT solver, and no arbitrary-formula performance guarantee is made.
- `verify_sop_with_bdd` builds a truth-table reference and a selected-cover graph, masks don't-care rows, and checks that their difference is false over every cared row. Circuit examples run this check alongside their explicit expected-output vectors.

## Refinement invariant

A cube stores a value mask and a wildcard mask. Two cubes merge only when their wildcard masks match and exactly one specified bit differs. Each merge round keeps one copy of each resulting shape. A cube is reported as prime after a round in which it cannot merge further; don't-care-only cubes are excluded from the reported prime list.

The first stage stops at prime implicants. It does not yet choose a cover, claim a globally minimal gate network, or model propagation delay and loading.

## Cover selection

The chart contains only required one-rows; don't-care rows may expand a prime but do not need coverage. A required row with one chart entry makes that prime essential. The exact selector starts with all primes as a valid upper bound, seeds the search with essential primes, then branches on the uncovered row with the fewest remaining coverers. It memoizes sorted selected-index states and uses a maximum-new-coverage lower bound to prune branches.

Covers are ranked by fewest product terms, then fewest total literals, then the lexicographically smallest sorted pattern list, with `- < 0 < 1`. The chart sorts patterns in that same order, so the final tie-break is stable.

## Decision points for later increments

- Add POS rendering without changing the current SOP contract.
- Measure BDD table lookup and memory behavior on a published corpus before choosing a hash-based unique table or a SAT/CNF backend.
- Define a bounded formula input language and independent solver oracle before claiming SAT support; z3 is a reference point, not an implemented dependency.
- Explore NAND/NOR technology mapping only with a separately documented cost and verification model.
- Add pin-level wiring guidance only after selecting exact orderable device variants and reviewing their current datasheets.

## Two-level gate-count estimate

`estimate_sop_gate_cost` maps each selected product to a two-input AND tree and
joins multiple products with a two-input OR tree. An input complement is
counted once per variable and shared by every product that needs it. A single
literal or a one-product sum needs no AND or OR gate in this structural model.
`GateCost::packages_for` rounds a nonnegative channel count up to whole
packages; it does not choose a part.

The public `GateCost::new` rejects negative counts and totals that exceed the
signed 32-bit `Int` range. Package rounding uses quotient and remainder so the
ceiling calculation does not overflow when the requested gate count is near
`Int`'s maximum. Regression tests cover that numeric boundary and sparse
eight-input truth tables, including row 255 where the most significant bit is
set.

This estimate is intentionally limited to gate counts for a direct SOP
implementation. It does not perform technology mapping, exploit NAND/NOR
forms, share internal product subexpressions, estimate delay or power, check
fan-out, or account for board wiring and unused package inputs. The part
catalog records channel counts from manufacturer documentation, while a real
build still needs a selected package variant and datasheet-level electrical
checks.
