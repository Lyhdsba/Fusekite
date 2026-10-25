# 十月验收：GitHub 与标准对照

核验日期：2026-10-25（Asia/Shanghai）。本记录核对的起始版本为
[`426836a70714a4c364800f7be87bec5ea33ff752`](https://github.com/Lyhdsba/Fusekite/tree/426836a70714a4c364800f7be87bec5ea33ff752)，
不发布 Mooncakes，也不将初审通过等同于最终验收通过。

## 规则来源与适用范围

- [十月官网](https://moonbitlang.github.io/Hackathon2026/#requirements)：本轮实际读取官网加载的中文内容，六项标准见下表；报名与验收截止为 2026-10-31。
- [赛事章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)：本轮从公开页面正文读取验收条款，包括检查/构建/测试 CI、Mooncakes 发布、开源许可，以及完成申报阶段约定的主要功能。页面仍保留九月赛程日期，不能用它覆盖十月官网的截止日期。章程另有不少于 10 个有效 commits 的申报要求；不能将这个数字误称为官网六项标准的原文。
- 参赛者提供的十月初审邮件文字：通过审核后不需再交表格，继续开发并上传 GitHub；所附九条要求包括 `moonc >= 0.10.14` 和 Mooncakes 发布。该邮件是用户提供的材料，不是本仓库独立查询邮箱所得。
- 参赛者同时提供过九月指南截图。本轮原图不可访问，不能声称逐字重新核对过原图；下面九项以用户粘贴文字和本轮可读取的章程逐项交叉核对。未发现可独立核实、单独发布的十月版指南，不能据此断言其不存在。

## 官网六项标准

| 标准 | 已核实证据 | 结论与边界 |
| --- | --- | --- |
| MoonBit 为主 | 核心库、SAT、QF_BV、器件目录和示例均为 `.mbt`；GitHub languages API 返回 MoonBit 143,179 字节、Python 9,436 字节、AMPL 648 字节。 | MoonBit 为主要实现语言。语言识别统计不是人工代码量或质量证明。 |
| 仓库公开 | 匿名访问仓库 HTTP 200；GitHub API 返回 `private=false`、`visibility=public`；开发历史、提交和 Actions 可追踪。 | 公开性已核实；提交时间集中情况见下文。 |
| 能够运行 | [README](../README.md)、[使用指南](使用指南.md)、[测试审查](acceptance-stage2.md)、两个可执行入口和 CI。 | 本轮运行通过；仅覆盖所记录工具链与默认 Wasm 目标。 |
| 工作有效 | 十月新增 POS 化简、独立成本校验、BDD/SAT 验证、消费者、POS 门数/封装估算及证据门禁修复。 | 有可定位的本期实质增量；九月 ROBDD/SAT/QF_BV/SOP 基线不计作十月新增。最终有效性由赛事评审认定。 |
| 开源合规 | [Apache-2.0 LICENSE](../LICENSE)、[模块元数据](../moon.mod)、[来源对照](MoonBDD与Fusekite范围对比.md)、[TI 器件资料索引](../parts/74hc-catalog.md)。 | 许可和参考来源可查；没有 MoonBDD 代码/API 集成的声明。 |
| AI 可解释 | [开发说明](../DEVELOPMENT.md#direction-and-ai-assistance)披露 AI 对代码、测试、示例、文档与 CI 的实质贡献；[设计契约](../DESIGN.md)说明选择和边界。 | 文档证据具备；自动化不能证明参赛者本人理解、人工审阅或硬件验证，此项不标为自动通过。 |

## 邮件九项要求与九月参考材料对照

| 项 | 要求 | 当前证据与状态 |
| --- | --- | --- |
| 1 | MoonBit 为主，`moonc >= 0.10.14` | 使用固定 `v0.10.15+943464bfa`，本机与起始版本 CI 均确认版本；满足邮件版本下限。 |
| 2 | GitHub 公开，提交清晰 | 匿名访问、仓库 API、分支和真实 diff 均核实，见下文。 |
| 3 | 结构清晰，实现声明的核心功能 | [项目结构](../README.md#project-shape)、[实现契约](../DESIGN.md)、70 项 MoonBit 测试与示例对应 README 已实现范围。未读取或修改本地备用申报书；不能借此证明已与正式获批 Proposal 的每项承诺逐字一致。 |
| 4 | README 说明目标、安装、使用、示例，可复现 | 文档包含完整源码消费命令和有条件的 `moon add Lyhdsba/fusekite` 安装说明。源码消费已运行；注册表安装仍待发布后验证。 |
| 5 | CI 覆盖检查、构建、测试 | [workflow](../.github/workflows/ci.yml) 包含格式、无警告检查、测试、构建、两类示例、Python 回归、Z3、文档和包清单。起始提交的所有步骤成功。 |
| 6 | 至少一个可运行示例 | `moon run cmd/main` 与 `moon -C examples/status-indicator run .` 均通过断言；前三个电路分别检查 4、10、8 个 cared rows，消费者检查全部 16 行和反例行 10。 |
| 7 | 完整测试覆盖核心路径 | [stage 2](acceptance-stage2.md)列明覆盖与未覆盖边界；本轮 70 项 MoonBit、10 项 Python 和 3,586 项 Z3 检查通过。有限枚举不是任意公式、所有平台或硬件正确性的证明。 |
| 8 | 发布到 mooncakes.io | **本阶段未完成此项。** `moon.mod` 的名称 `Lyhdsba/fusekite`、版本 `0.2.0` 及本地打包结果不是注册表发布证据；后续需记录真实发布版本和脱离源码工作区的消费者安装。 |
| 9 | OSI 认可许可，参考/移植遵守来源许可 | GitHub license API 识别为 Apache-2.0；README、元数据和 LICENSE 一致。MoonBDD 为固定版本范围比较对象，TI 资料用于器件通道数来源；未声称复用它们的实现。 |

## GitHub 真实状态与十月增量

起始核验时，本地 `main`、`origin/main`、`git ls-remote` 与 GitHub branch API
均为 `426836a70714a4c364800f7be87bec5ea33ff752`；默认分支 `main`，
仓库未归档、未禁用。GitHub 贡献者 API 列出 Lyhdsba，贡献数为 50；
该统计不能证明所有代码由本人手写。

以 Asia/Shanghai 的 2026-10-01 至 2026-11-01 为日期区间，起始 HEAD 可达历史
有 17 条十月提交；逐条比较父树均有改动。它们分布在 10 月 14、15、16、24、25 日，
不能描述成每日连续开发，也不能把 17 条非空记录全部自动认定为有效功能贡献。
以下选择有实际实现或验证改动的里程碑，而非用整理文档的数量证明达标：

| 日期 | 提交 | 可复核增量 |
| --- | --- | --- |
| 10-15 | [`4cf0228`](https://github.com/Lyhdsba/Fusekite/commit/4cf02288d6230d90af1fea22f9c88f9f9140bd6a) | POS 类型、精确化简及小表校验。 |
| 10-15 | [`615c352`](https://github.com/Lyhdsba/Fusekite/commit/615c352b80197ed46e7bfe0a6d5514eeebef9675) | POS 独立成本 oracle、BDD/SAT 验证及反例重放。 |
| 10-15 | [`6e5ae9e`](https://github.com/Lyhdsba/Fusekite/commit/6e5ae9e98f4971d35ce36d4bbc8be32c9bf658f5) | 独立消费者模块和 CI 执行入口。 |
| 10-16 | [`edf685c`](https://github.com/Lyhdsba/Fusekite/commit/edf685c3e53678336869e5320f2967b576983946) | POS 直接门数和 74HC 封装估算，接入三组电路。 |
| 10-25 | [`426836a`](https://github.com/Lyhdsba/Fusekite/commit/426836a70714a4c364800f7be87bec5ea33ff752) | SOP 核验回归、QF_BV 完整键集合及模型边界门禁、10 项 Python 回归。 |

不制造空提交、不拆分凑数、不改写公开历史。仓库与 MoonBDD 仍共享 ROBDD 和
布尔分析能力；[固定版本对照](MoonBDD与Fusekite范围对比.md)及上述增量解释应用流程
差异，不证明全生态独有，也不保证评审结论。参赛者已报告通过十月初审，
本记录不把旧的九月驳回意见误作当前初审状态。

## 已验证的 Actions 与本轮复现

起始提交对应 [Actions run 40146045134](https://github.com/Lyhdsba/Fusekite/actions/runs/40146045134)
已完成且 `success`；本轮逐步核对 `verify` job 和日志：70 项 MoonBit 测试、10 项
Python 回归、3,586 项 Z3 差分及所有其他门禁均成功。该运行只证明所链接提交，
不认证本记录之后的新提交；新推送需另核对其 `headSha` 与最终结论。

本轮 Windows 复现使用已安装的 Moon `0.1.20261012` / moonc
`v0.10.15+943464bfa` 和已有隔离环境的 Python `3.12.14` / 固定 Z3。
实际通过 README 中的格式、无警告检查、70 项测试、构建、内置示例、消费者
format/check/run、API 文档、包清单，以及 10 项 Python 回归和 3,586 项 Z3 检查。
没有声称本轮重新安装工具链或建立了新的隔离环境。

本地备用申报书及 `output/` 保持未跟踪，未读取或修改；包清单也不包含它们。
此记录补齐此前缺少的六项/九项证据映射和精确 CI 对应关系，没有新增运行时功能。

代码和工程证据已具备供验收审查的基础。整体仍需完成真实 Mooncakes 发布、
注册表安装复现，并由参赛者核实本人理解及正式获批目标的完成情况；不能据当前
自动化结果声称已全面通过最终验收、独立人工审阅或硬件验证。
