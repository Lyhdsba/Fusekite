# MoonBDD 与 Fusekite：已实现范围对比

基线核对日期：2026-10-14；十月增量复核：2026-10-15（Asia/Shanghai）。本文帮助使用者比较固定版本的能力与边界，不表示两个项目已经集成，也不作为性能排名。

## 版本与证据

- MoonBDD：核对公开仓库提交 [`1c43647849d4b1033edb9743e45199da2746f3d4`](https://github.com/oyjh0381/MoonBDD/tree/1c43647849d4b1033edb9743e45199da2746f3d4)。下文 M1–M4 均固定到该提交，不把未来规划算作实现。
- Fusekite：九月实现基线为已推送提交 [`3371536742257f3834f71120b9009dd3ef820539`](https://github.com/Lyhdsba/Fusekite/tree/3371536742257f3834f71120b9009dd3ef820539)。下文 F1–F6 均固定到该提交，表格据此比较；十月 POS 增量另列于下一节，不混入九月成果。
- 对“未实现”的判断限于这些版本的公开文档、API 和本地源码核对，不推断项目作者今后的计划。

## 十月新增与比较边界

截至 [`9d3c9df`](https://github.com/Lyhdsba/Fusekite/tree/9d3c9df8a75c287daad44afa2407338e4b5fd62e)，Fusekite 新增了单输出、1–8 输入的精确 POS 化简、独立 `PosClause`/`PosSolution`、求值及专用 BDD/SAT 核验，并补齐三个 SOP/POS 电路对照。见固定版本的 [POS 实现](https://github.com/Lyhdsba/Fusekite/blob/9d3c9df8a75c287daad44afa2407338e4b5fd62e/pos.mbt)、[验证器](https://github.com/Lyhdsba/Fusekite/blob/9d3c9df8a75c287daad44afa2407338e4b5fd62e/pos_verify.mbt)与[独立 oracle](https://github.com/Lyhdsba/Fusekite/blob/9d3c9df8a75c287daad44afa2407338e4b5fd62e/pos_test.mbt)。POS 复用本项目的补函数 SOP 精确覆盖，不是 MoonBDD 代码复用；器件估算仍仅支持 SOP。上述固定版本的 MoonBDD 公开 API 未提供该精确 POS 选择流程。这不构成对整个 Mooncakes 生态不存在同类项目的断言。

## 共同基础与不同交付目标

两个项目都提供 MoonBit 原生 ROBDD 和布尔运算，均可用于数字逻辑分析；因此不能把“MoonBit BDD”“布尔等价检查”或“数字逻辑场景”本身作为 Fusekite 独有能力。MoonBDD 面向更丰富的 BDD 分析和有限状态空间探索，Fusekite 的区别在于独立 CNF/Tseitin/DPLL 路径、受限 QF_BV 位爆炸，以及从小真值表精确 SOP 到门数和整片器件估算的应用链路。[M1]、[M2]、[F1]、[F2]、[F3]、[F4]、[F5]

| 范围 | MoonBDD 已实现 | Fusekite 已实现及边界 | 证据 |
| --- | --- | --- | --- |
| ROBDD 与布尔分析 | 显式 Manager 所有权、唯一表、ITE 缓存；表达式解析、限制、替换、存在/全称量化；模型枚举和精确十进制模型计数 | 固定变量序的 1–32 变量管理器，AND/OR/XOR、取反、求值和同一管理器内规范节点等价；没有上述解析、量化或模型计数 API，查找结构为线性扫描 | M1、M2、M3；F1 |
| BDD 工具与状态探索 | JSON/DOT、显式及相邻交换变量重排、有限状态可达固定点和可选不变式反例；资源预算覆盖多种入口 | 当前没有变量重排、JSON/DOT 或状态可达性接口；电路示例是组合逻辑验证，不是时序状态探索 | M2、M3；F1、F6 |
| CNF/Tseitin/DPLL | README 明确排除 SAT/SMT 求解；`sat_one` 等接口在 BDD 上检查满足性、取得模型，不能据名称称为 CNF/DPLL 后端 | 独立 `sat/` 包：CNF 校验/规范化、DIMACS 解析、共享重复子表达式的 Tseitin 编码、两观察文字传播和确定性 DPLL；返回模型、UNSAT 或预算耗尽 Unknown | M1、M3；F2 |
| 受限 QF_BV | 所核对版本没有位向量约束前端；布尔量化也不等于位向量 SMT | `smt/` 支持 1–8 位常量/变量、同宽按位运算、回绕加减、低位乘法、等值和有符号/无符号小于；经布尔表达式、Tseitin CNF 和 DPLL 求解 | M1、M3；F3 |
| SOP 生成与最小化 | `enumerate_cubes` 沿 ROBDD 真终端路径枚举互不相交的满足 cube；API 未提供素蕴含项精确最小 SOP 选择，路径 cube 枚举不能当作最小化保证 | 单输出、1–8 输入，允许无关项；Quine–McCluskey 素蕴含项、覆盖表、本质项和精确搜索。依次最小化项数、文字数，再以模式字典序确定唯一选择 | M2、M4；F4 |
| 等价与反例 | BDD 语义关系检查可返回反例，包含等价、蕴含和不相交检查；并非“只能表示函数” | 对候选 SOP 在 cared rows 上进行 BDD 独立复核，并以 `(expected XOR cover) AND care` 查询 SAT：SAT 返回输入反例，UNSAT 才表示等价，Unknown 保留未知 | M2、M3；F1、F2 |
| 电子门数与封装规划 | 有数字逻辑示例；所核对 API 未提供直接 SOP 门数到 74HC 封装的估算接口 | 二输入 AND/OR 树和共享输入反相的结构计数；按 SN74HC04/08/32 通道数分别向上取整。目录另含 SN74HC00，但当前映射不做 NAND 优化 | M1、M3；F5、F6 |

## Fusekite 差异化的准确表述

Fusekite 增加的是可独立调用的 SAT 后端和有明确边界的位向量前端。CNF 上限为 4,096 个变量；表达式入口最多 256 个源变量，编码仍受 4,096 变量边界限制。DPLL 搜索预算为 1–1,000,000 个搜索节点，使用时间顺序回溯，没有 CDCL、冲突学习或工业性能保证。Unknown 不能写成 UNSAT；UNSAT 结果也不意味着已经输出可供外部检查的证明证书。[F2]

QF_BV 将当前支持的定宽操作降为 SAT，保留 SAT、UNSAT、Unknown 和非法输入的区别；有符号能力仅为小于比较。不支持除法、移位、拼接、数组、未解释函数、量词或 SMT-LIB 解析，没有原生理论传播，不是完整 SMT 求解器。已记录的固定 Z3 差分语料用于验证现有实现，Z3 是测试工具，不是 Fusekite 的运行时求解后端；各版本实际运行结果见开发验证记录。[F3]

“精确最小”限定为给定单输出真值表在无关项允许范围内、上述项数/文字数目标下的两级 SOP，不保证任意门网络、封装数量、时延或功耗全局最优。BDD 与 SAT 验证只证明 cared rows 上的布尔等价，不能替代电气验证。门数估算及器件封装折算用于早期方案规划，不包含技术映射、引脚布线、扇出、时序、价格或实体实验结论。[F1]、[F2]、[F4]、[F5]、[F6]

MoonBDD 已有 Fusekite 尚未提供的解析、量化、模型计数、重排、图/JSON 输出和可达性功能；本对比不宣称 Fusekite 全面替代或优于 MoonBDD。两者有基础重叠，但交付范围不同。Fusekite 当前 `moon.mod` 和包导入没有 MoonBDD 依赖，本文没有声明代码复用、已完成集成、对方认可或联合开发；未来互操作需另外实现和验证。[M1]、[M2]、[F6]

## 固定版本来源索引

### MoonBDD

- **M1 — [README](https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/README.md)**：项目目标、实现概要、数字逻辑示例及明确排除的 SAT/SMT 范围。
- **M2 — [API 文档](https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/docs/API.md)**：模型、关系反例、cube 路径枚举、重排和有限可达性契约。
- **M3 — [公开 API 签名](https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/pkg.generated.mbti)**：核对实际公开接口，避免将功能名称误读为其他后端。
- **M4 — [算法与复杂度](https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/docs/ALGORITHMS.md)**：路径 cube 枚举、资源界限和 ROBDD 最坏增长。

### Fusekite

- **F1 — [ROBDD 源码](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/bdd.mbt)**、[设计契约](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/DESIGN.md)：管理器范围、规范性和 BDD SOP 验证。
- **F2 — [CNF/编码/求解器](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/sat/solver.mbt)**、[SAT SOP 验证](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/sat_verify.mbt)：输入边界、Tseitin 共享、传播/回溯及结果状态。
- **F3 — [QF_BV 源码](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/smt/bitvec.mbt)**、[Z3 差分工具](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/tests/qfbv_z3_oracle.py)、[开发验证记录](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/DEVELOPMENT.md)：操作范围、降低路径及已有软件验证证据。
- **F4 — [真值表与素蕴含项](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/fusekite.mbt)**、[覆盖表](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/coverage.mbt)、[精确选择](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/cover.mbt)：规格边界及最小化排序目标。
- **F5 — [门数模型](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/gate_cost.mbt)**、[器件目录与折算](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/parts/catalog.mbt)、[TI 数据表索引](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/parts/74hc-catalog.md)：直接 SOP 模型、通道数来源和封装估算限制。
- **F6 — [电路示例](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/circuits/examples.mbt)**、[模块元数据](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/moon.mod)、[根包导入](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/moon.pkg)、[QF_BV 包导入](https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/smt/moon.pkg)：示例性质和当前项目依赖。

[M1]: https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/README.md
[M2]: https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/docs/API.md
[M3]: https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/pkg.generated.mbti
[M4]: https://github.com/oyjh0381/MoonBDD/blob/1c43647849d4b1033edb9743e45199da2746f3d4/docs/ALGORITHMS.md
[F1]: https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/bdd.mbt
[F2]: https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/sat/solver.mbt
[F3]: https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/smt/bitvec.mbt
[F4]: https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/cover.mbt
[F5]: https://github.com/Lyhdsba/Fusekite/blob/3371536742257f3834f71120b9009dd3ef820539/parts/catalog.mbt
[F6]: https://github.com/Lyhdsba/Fusekite/tree/3371536742257f3834f71120b9009dd3ef820539
