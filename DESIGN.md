# Design contract

## Input model

- A function has one output and 1–8 input bits.
- Row numbers are unsigned binary indices. The first input is the most significant bit.
- The on-set and don't-care set are unique, disjoint, and within the truth-table range.
- Rows omitted from both sets are required zeroes.

## Refinement invariant

A cube stores a value mask and a wildcard mask. Two cubes merge only when their wildcard masks match and exactly one specified bit differs. Each merge round keeps one copy of each resulting shape. A cube is reported as prime after a round in which it cannot merge further; don't-care-only cubes are excluded from the reported prime list.

The first stage stops at prime implicants. It does not yet choose a cover, claim a globally minimal gate network, or model propagation delay and loading.

## Decision points for later increments

- The cover solver must preserve every required one while never covering a required zero.
- Covers are ordered by fewest product terms, then fewest total literals, then the lexicographically smallest sorted pattern list, with `- < 0 < 1`.
- Device-level costs should come from an explicit, versioned part catalog rather than guessed datasheet values.
- Example circuits will state their assumptions and show how to verify them against a physical part's datasheet.
