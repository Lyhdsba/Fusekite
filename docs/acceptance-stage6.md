# 十月验收阶段 6：组委会视角最终审计

核验日期：2026-10-26（Asia/Shanghai）。这是 AI 辅助的证据审计，不是组委会
决定或独立人工评审。起始本地 `main`、远端 `main` 与 GitHub Actions 的提交为
[`8f4d44bebd3273bbefdb14c0d6c2f4419cceaa43`](https://github.com/Lyhdsba/Fusekite/tree/8f4d44bebd3273bbefdb14c0d6c2f4419cceaa43)。

## 可否验收

**技术材料具备提交最终验收的条件；无条件最终结项暂不能确认。** 本轮未发现
阻止已声明软件功能运行、公开源码复现或安装已发布版本的技术问题。MoonBit
主体、十月实质增量、文档/示例/测试/CI、真实 Mooncakes 版本及开源许可均有
下面的可追踪证据。但“参赛者本人掌握目标、路径和质量”及“完成正式获批目标”
仍需参赛者本人陈述和复核，不能由提交者账号、AI 文档或自动化通过代替。
贡献有效性、选题重合及最终验收由组委会认定。

## 本轮规则来源

- 重新读取[十月官网](https://moonbitlang.github.io/Hackathon2026/#requirements)
  加载的[中文内容](https://moonbitlang.github.io/Hackathon2026/assets/index-Cb3Bwakq.js)：
  六项标准仍为 MoonBit 主体、公开且可追踪、可运行、当期实质工作、开源合规、
  AI 使用可解释；十月截止为 2026-10-31。官网还要求入赛事群并以 GitHub ID
  设置昵称，这属于本人需核实的参赛手续，仓库无法证明。
- 重新读取[公开赛事章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)
  的正文数据：README、示例、核心路径测试、检查/构建/测试 CI、Mooncakes、
  OSI 许可与来源，以及完成申报约定功能的条款可查。章程仍有九月日期，十月
  截止采用十月官网。其申报要求含不少于 10 个有效 commits，禁止凑数。
- [阶段 3](acceptance-stage3.md)保留此前用户提供的初审邮件文字及材料来源边界。
  本轮没有查询邮箱或重新核实不可访问的旧截图；`moonc >= 0.10.14` 沿用该邮件
  记录。没有读取本地备用申报书来推断正式获批 Proposal。

## 六项标准与九项工程要求交叉核对

| 项目 | 当前证据 | 审计结论 |
| --- | --- | --- |
| MoonBit 主体、编译器下限 | [模块](../moon.mod)、[源码](../README.md#project-shape)、[SDK 固定值](../.moonbit-version)；本机 moonc `v0.10.15+943464bfa`。GitHub languages API 本轮返回 MoonBit 143,179 字节、Python 12,702、AMPL 648。 | 主要实现为 MoonBit；所用编译器满足记录的版本下限。语言识别不是人工代码量证明。 |
| GitHub 公开、记录可追踪 | [公开仓库](https://github.com/Lyhdsba/Fusekite)、[main 提交历史](https://github.com/Lyhdsba/Fusekite/commits/main/)、[仓库 API](https://api.github.com/repos/Lyhdsba/Fusekite)。本轮匿名 HTTP 200，API `isPrivate=false`，默认分支 `main`。 | 公开性及真实提交可查；不是每日持续开发的声明。 |
| 本期工作有效 | 下面列明十月 POS、验证、消费者、器件估算及证据门禁的实际 diff。 | 有本期实质增量；不将九月基线充作新增。有效贡献数与价值仍由评审认定。 |
| 结构与核心功能 | [结构说明](../README.md#project-shape)、[设计契约](../DESIGN.md)、[测试审计](acceptance-stage2.md)。本轮核对 POS 补集复用、零模式极性、常量与 don't-care 处理、对应测试及器件来源字段。 | 已声明的功能有实现与软件验证；正式获批目标逐项一致性待本人确认。 |
| README、安装、使用、示例 | [README](../README.md)、[中文指南](使用指南.md)、[三组电路](../circuits/WORKED.md)、[独立消费者](../examples/status-indicator/README.md)。 | 两个源码入口及注册表消费均实际运行。 |
| 检查/构建/测试 CI | [主 CI](../.github/workflows/ci.yml)及[注册表 workflow](../.github/workflows/registry-consumer.yml)；起始提交的两条成功运行见下文。 | 包含必需门禁；注册表 workflow 为手动触发。未审核分支保护。 |
| 核心路径测试 | 70 项 MoonBit 测试、10 项 Python 回归、3,586 项真实 Z3 差分，本轮全部通过。POS 还覆盖全部 6,561 个三输入三值规格及独立成本 oracle。 | 有有限软件验证；不能声称任意公式、全部 4–8 输入函数、所有平台或物理正确性。 |
| Mooncakes 发布 | [`Lyhdsba/fusekite@0.2.0`](https://mooncakes.io/docs/Lyhdsba/fusekite)、CLI 查询及独立消费者；详见下一节。 | 真实版本存在、未撤回、可安装并执行 API；已关闭阶段 3 的待发布项。 |
| OSI 许可与来源 | [Apache-2.0 LICENSE](../LICENSE)、[元数据](../moon.mod)、[OSI 官方条目](https://opensource.org/license/apache-2.0)、[MoonBDD 固定版本范围对照](MoonBDD与Fusekite范围对比.md)、[TI 来源索引](../parts/74hc-catalog.md)。 | 许可一致且 OSI 认可；参考资料可查。当前模块未声明 MoonBDD 依赖/适配接口。不能由文档推断全代码独立创作或完成法律审计。 |
| AI 披露与本人掌握 | [开发说明](../DEVELOPMENT.md#direction-and-ai-assistance)披露 AI 对分析、代码、测试、示例、CI、文档和验证的实质贡献；[设计契约](../DESIGN.md)可供答辩。 | 披露具备；本人理解证据尚待本人提供，不自动标为通过。 |

## 十月贡献可追踪性

以起始 `8f4d44b` 为界，可达历史共 52 个提交；按 Asia/Shanghai 的十月区间
查询有 19 个提交，逐条父树比较均非空，日期集中于 10-14、15、16、24、25、26。
这些数字不等于 19 个均为有效功能贡献，也不替代章程对有效 commits 的评审。
所有历史作者/提交者字段均为 Lyhdsba；它们不证明全部手写或人工审阅。

| 提交 | 本期实际变化 |
| --- | --- |
| [`4cf0228`](https://github.com/Lyhdsba/Fusekite/commit/4cf02288d6230d90af1fea22f9c88f9f9140bd6a) | POS 类型与精确化简，独立小表 oracle。 |
| [`615c352`](https://github.com/Lyhdsba/Fusekite/commit/615c352b80197ed46e7bfe0a6d5514eeebef9675) | POS 独立成本与语义校验、直接 BDD/SAT 验证、反例重放。 |
| [`fc6100c`](https://github.com/Lyhdsba/Fusekite/commit/fc6100cc8cc2b44b358ccaa976a1c77421a171cb) | 可执行 SAT 模型重放、预算结果与 QF_BV 具体值断言。 |
| [`6e5ae9e`](https://github.com/Lyhdsba/Fusekite/commit/6e5ae9e98f4971d35ce36d4bbc8be32c9bf658f5) | 独立业务消费者及全部 16 行、错误候选的 API 验证与 CI。 |
| [`7279bcf`](https://github.com/Lyhdsba/Fusekite/commit/7279bcfaeb8e024631d938377fb1ee3e4044890a) | 固定 SDK、安装/版本检查及可复现工具链说明。 |
| [`edf685c`](https://github.com/Lyhdsba/Fusekite/commit/edf685c3e53678336869e5320f2967b576983946) | POS 直接门数、74HC 封装估算及三组电路集成。 |
| [`426836a`](https://github.com/Lyhdsba/Fusekite/commit/426836a70714a4c364800f7be87bec5ea33ff752) | SOP 回归、完整 QF_BV 键集合/模型门禁与失败注入测试。 |
| [`8f4d44b`](https://github.com/Lyhdsba/Fusekite/commit/8f4d44bebd3273bbefdb14c0d6c2f4419cceaa43) | 仓库外注册表消费者与独立手动 CI。 |

九月 ROBDD/SAT/QF_BV/SOP 基线与十月增量分开说明；上述算法基础并不构成
全生态独有性主张。更多文档与工程变更保留在真实历史中，不拆分、不造空提交
来凑次数。请评审结合 diff 认定有效性，而非只看计数或自动化生成的结论。

## 发布与远程证据

本轮 `moon view Lyhdsba/fusekite@0.2.0 --json` 返回 `status=success`、
`yanked=false`、`latest_version=0.2.0`，元数据中的模块名、仓库、Apache-2.0
一致。注册表记录创建时间为 `2026-10-25T12:23:30.806614+00:00`，checksum 为
`2bed801dc374a10c3dbecd7c6f2b411debf28f4d97a9ccd993593d5dd0dc7b5d`。
这属于注册表响应，不是凭元数据推测已发布。

本轮再次执行 `python -B tests/registry_consumer.py --version 0.2.0`：创建仓库
外空消费者，刷新索引、解析指定版本、核对注册表模块清单和依赖树，再运行
格式、无警告检查与 API 断言。输出明确为缓存的注册表 `0.2.0`；未复制库源码
或本地 workspace，不声称本轮重新下载发行包。16 行规则、SOP/POS、两种验证、
反例行 10 及门/封装计数全部通过。首次下载证据见[阶段 5](acceptance-stage5.md)。

本轮逐步查询以下已完成运行，均对应起始 `8f4d44b`，所有 job/step 成功：

- [主 CI 40249415743](https://github.com/Lyhdsba/Fusekite/actions/runs/40249415743)。
- [注册表消费者 40249424258](https://github.com/Lyhdsba/Fusekite/actions/runs/40249424258)。

这些链接只证明各自 `headSha`，不能用来冒充本审计文档提交的 CI。后续推送的
运行应从[Actions](https://github.com/Lyhdsba/Fusekite/actions)按最终 SHA 核对。
本阶段不重新发布、不增加 Mooncakes 版本，也不改写历史。

## 本轮复现与真实修复

Windows 默认 Wasm 目标，已安装的 Moon `0.1.20261012` / moonc
`v0.10.15+943464bfa`，复用阶段 2 的隔离 Python `3.12.14` / Z3 `5.1.0.0`。
没有声称新装 SDK、重新建立 Python 环境或完成新的平台验证。

```sh
moon fmt --check
moon check --deny-warn
moon test
moon build
moon run cmd/main
moon -C examples/status-indicator fmt --check
moon -C examples/status-indicator check --deny-warn
moon -C examples/status-indicator run .
moon doc
python -B -m unittest discover -s tests -p 'test_*.py' -v
python -B tests/qfbv_z3_oracle.py
python -B tests/registry_consumer.py --version 0.2.0
moon package --list
git diff --check
```

上述检查通过。库测试为 70/70；Python 为 10/10；Z3 为 3,586 项。三组电路
核对 4/10/8 个 cared rows、SOP/POS BDD/SAT 等价性与估算；消费者核对 16 行
及反例。完整源码验证与发布版本消费分开执行。

首次当前工作区包清单发现一个无关的未跟踪 Word 文件会被打包，故补充
`.moonignore` 精确排除该本地文件。原文件未修改或纳入 Git；修复后重新核对
包清单和 ZIP 条目。`Fusekite_项目申报书.md`、`output/` 保持原样且未读取、
未暂存、未进入包。本轮另修复当前开发说明中仍把已完成发布描述为将来事项
的表述，并增加本最终审计的导航。未改变算法或公共 API。

## 必须由参赛者本人完成的结项说明

以下为待办，**不是已经完成的人工审阅记录，也不提供预填的个人声明**：

1. **正式获批目标复核。** 对照本人保存的正式获批 Proposal/初审反馈逐项
   指向实现、测试和示例，说明未完成或调整之处。当前 README 的计划功能
   （如 NAND/NOR 映射、冲突学习、更多 QF_BV 操作）不能自动视为获批范围外，
   也不能当作已完成。核实参赛方向、入群和 GitHub ID 昵称等本人手续。
2. **掌握项目与 AI 协作的本人陈述。** 用自己的话解释为何采用单输出 1–8
   输入范围、SOP/POS 极性和补集化简、don't-care、最优性排序、BDD 与 SAT
   的验证角色及 `Unknown` 边界、独立 oracle 的作用、直接门/封装估算边界。
   指出 AI 实质完成哪些部分、本人作过哪些设计判断和质量复核；仅记录实际
   做过的个人复现或修改经历。最好能现场解释一个输入、输出和反例。
3. **据实提交。** 本次是 AI 辅助源码检查与自动化软件验证；没有人工全量
   审查、真实用户反馈、本人独立复现、引脚/电气验证或硬件测试的新增证据。
   缺少这些证据不能被本审计转写成已完成，也不意味着已声明软件功能要求
   它们全部作为额外门槛。若申报曾承诺相关工作，应在第 1 项明确处理。

本轮自动化负责整理可验证的技术证据和修复，不代替个人陈述、正式参赛资格
确认、有效贡献裁定或组委会验收。参赛者完成上述本人事项后，可带本表、
固定提交的 CI 与真实发布版本提交最终验收。
