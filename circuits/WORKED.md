# Worked combinational circuits

Rows use the first listed input as the most significant bit. `1` means the
output is asserted; `x` marks a deliberately unspecified row. Equations use
`+` for OR, adjacency for AND, and `!` for inversion. These examples teach
small truth-table reduction; they are not safety-rated designs.

Run `moon run cmd/main` to compare both forms for every case. The executable
checks SOP literal simulation and POS evaluation against the listed expected
rows, then requires BDD and SAT equivalence for both forms. SAT uses a 100,000
search-node budget; `Unknown`, a counterexample, or invalid input fails the demo
instead of printing an equivalence claim. The unit tests also pin the selected
POS patterns and costs. Both forms are mapped as direct positive-logic
AND/OR trees; package figures round each device family separately.

POS zero patterns describe when a sum clause is false: `0` means a positive
literal, `1` an inverted literal, and `-` an omitted variable. The clauses are
ANDed together. This is the opposite polarity to SOP product patterns.

## Two-condition sensor interlock

Inputs are `door_closed` and `sensor_clear`, both active-high. Enable is true
only for row `11`, so `F = door_closed · sensor_clear`. The direct SOP uses one
AND2 gate: one SN74HC08 package (four channels available).

POS patterns `-0`, `0-` give `(sensor_clear) AND (door_closed)`, with two
single-literal clauses and two literals. The direct POS estimate is one AND2,
also one SN74HC08 package; both forms match all four rows.

| `door_closed sensor_clear` | 00 | 01 | 10 | 11 |
| --- | ---: | ---: | ---: | ---: |
| `enable` | 0 | 0 | 0 | 1 |

## BCD seven-segment segment a

Inputs `D8 D4 D2 D1` encode BCD 0–9. For a common-cathode display, segment
`a` is active-high for digits 0, 2, 3, 5, 6, 7, 8 and 9. Codes 10–15 are
don't-cares only under the stated assumption that the source is valid BCD; a
system that can emit those codes must define the outputs instead.

| Digit | D8 D4 D2 D1 | `a` |
| ---: | --- | ---: |
| 0 | 0000 | 1 |
| 1 | 0001 | 0 |
| 2 | 0010 | 1 |
| 3 | 0011 | 1 |
| 4 | 0100 | 0 |
| 5 | 0101 | 1 |
| 6 | 0110 | 1 |
| 7 | 0111 | 1 |
| 8 | 1000 | 1 |
| 9 | 1001 | 1 |
| 10–15 | invalid BCD | x |

The deterministic SOP patterns are `--1-`, `-0-0`, `-1-1`, `1---`, giving
`a = D2 + !D4·!D1 + D4·D1 + D8`. A direct mapping uses two AND2, three OR2
and two shared input inverters: one SN74HC08, one SN74HC32 and one SN74HC04
package. The catalog estimate excludes display current drivers and does not
imply that a logic output can drive an LED directly.

POS patterns `-100`, `0001` give
`a = (!D4 + D2 + D1) · (D8 + D4 + D2 + !D1)`: two clauses and seven literals.
This reduces clause count relative to SOP's four terms, but increases literals
relative to SOP's six. Both agree on digits 0–9; code 12 produces SOP 1 and
POS 0, which is permitted by its don't-care designation. Neither completion is
a required behavior for invalid BCD. A direct POS mapping uses two shared input
inverters, one AND2, and five OR2 gates: one SN74HC04, one SN74HC08, and two
SN74HC32 packages. This estimate preserves the selected POS form; it does not
search for a cheaper mixed-polarity or NAND/NOR network.

## Two-of-three sensor alarm

Inputs `sensor_A`, `sensor_B`, `sensor_C` are active-high; alarm asserts for
any pair or for all three. The truth table is `000,001,010,100 → 0` and
`011,101,110,111 → 1`. Its cover is `-11 + 1-1 + 11-`, the usual majority
function `A·B + A·C + B·C`. A direct two-level mapping uses three AND2 and two
OR2 gates: one SN74HC08 and one SN74HC32 package.

POS patterns `-00`, `0-0`, `00-` give `(B + C) · (A + C) · (A + B)`.
Both forms have three terms/clauses and six literals and match all eight rows.
The direct POS tree uses two AND2 and three OR2 gates, one SN74HC08 and one
SN74HC32 package.

Each worked case has a separately authored expected output vector in
`examples.mbt`, distinct from the on-set used to construct its truth-table
specification. Example construction rejects vectors inconsistent with the
specified on-set and don't-care rows. Tests compare the minimized cover against
that vector, including all specified zero rows and excluding only the BCD
don't-cares. A separate literal-by-literal SOP evaluator also simulates every
specified input combination for all three examples. Each example runs ROBDD
equivalence and a SAT counterexample query for both SOP and POS; only a proved-UNSAT mismatch query
is recorded as equivalent. These are software-level Boolean checks, not an
external HDL simulator run; no physical device or breadboard test is claimed.
