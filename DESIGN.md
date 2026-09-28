# Design contract

## Input model

- A function has one output and 1–8 input bits.
- Row numbers are unsigned binary indices. The first input is the most significant bit.
- The on-set and don't-care set are unique, disjoint, and within the truth-table range.
- Rows omitted from both sets are required zeroes.

## Refinement invariant

A cube stores a value mask and a wildcard mask. Two cubes merge only when their wildcard masks match and exactly one specified bit differs. Each merge round keeps one copy of each resulting shape. A cube is reported as prime after a round in which it cannot merge further; don't-care-only cubes are excluded from the reported prime list.

The first stage stops at prime implicants. It does not yet choose a cover, claim a globally minimal gate network, or model propagation delay and loading.

## Cover selection

The chart contains only required one-rows; don't-care rows may expand a prime but do not need coverage. A required row with one chart entry makes that prime essential. The exact selector starts with all primes as a valid upper bound, seeds the search with essential primes, then branches on the uncovered row with the fewest remaining coverers. It memoizes sorted selected-index states and uses a maximum-new-coverage lower bound to prune branches.

Covers are ranked by fewest product terms, then fewest total literals, then the lexicographically smallest sorted pattern list, with `- < 0 < 1`. The chart sorts patterns in that same order, so the final tie-break is stable.

## Decision points for later increments

- Add POS rendering without changing the current SOP contract.
- Device-level costs should come from an explicit, versioned part catalog rather than guessed datasheet values.
- Example circuits will state their assumptions and show how to verify them against a physical part's datasheet.

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
