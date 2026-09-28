# 74HC catalog assumptions

The small catalog in `catalog.mbt` records the logic function and number of
independent channels per package stated on the Texas Instruments SN74HC
datasheets:

| Device | Primitive | Channels/package | Inputs/channel | Primary source |
| --- | --- | ---: | ---: | --- |
| SN74HC00 | NAND2 | 4 | 2 | [TI datasheet](https://www.ti.com/lit/ds/symlink/sn74hc00.pdf) |
| SN74HC08 | AND2 | 4 | 2 | [TI datasheet](https://www.ti.com/lit/ds/symlink/sn74hc08.pdf) |
| SN74HC32 | OR2 | 4 | 2 | [TI datasheet](https://www.ti.com/lit/ds/symlink/sn74hc32.pdf) |
| SN74HC04 | NOT | 6 | 1 | [TI datasheet](https://www.ti.com/lit/ds/symlink/sn74hc04.pdf) |

These are family-level catalog entries, not complete bills of materials. The
exact suffix selects a package and may affect pin numbering and physical
layout. A builder must check the selected manufacturer's current datasheet for
supply range, input thresholds, output current, fan-out, timing, temperature
range, decoupling and unused inputs. The catalog intentionally does not store
price, stock, propagation delay, drive capacity or guaranteed cross-vendor
equivalence. Package estimates round each primitive family separately and
leave unused channels visible as package slack; they do not perform NAND/NOR
technology mapping or optimize across package families.
