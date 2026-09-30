# Worked combinational circuits

Rows use the first listed input as the most significant bit. `1` means the
output is asserted; `x` marks a deliberately unspecified row. Equations use
`+` for OR, adjacency for AND, and `!` for inversion. These examples teach
small truth-table reduction; they are not safety-rated designs.

## Two-condition sensor interlock

Inputs are `door_closed` and `sensor_clear`, both active-high. Enable is true
only for row `11`, so `F = door_closed · sensor_clear`. The direct SOP uses one
AND2 gate: one SN74HC08 package (four channels available).

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

## Two-of-three sensor alarm

Inputs `sensor_A`, `sensor_B`, `sensor_C` are active-high; alarm asserts for
any pair or for all three. The truth table is `000,001,010,100 → 0` and
`011,101,110,111 → 1`. Its cover is `-11 + 1-1 + 11-`, the usual majority
function `A·B + A·C + B·C`. A direct two-level mapping uses three AND2 and two
OR2 gates: one SN74HC08 and one SN74HC32 package.

Each worked case has a separately written expected output vector in
`examples.mbt`; the tests compare the minimized cover against that vector,
including all specified zero rows and excluding only the BCD don't-cares. Each
example also runs ROBDD equivalence and a SAT counterexample query; only a
proved-UNSAT mismatch query is recorded as equivalent.
