# 独立消费者：项目状态指示灯

这是独立的 MoonBit 模块 `example/status-indicator`，使用 Fusekite 的公开
API，将本示例项目的状态规则化简、核对并估算直接门实现。它不导入
`circuits/`，也不调用库内置的三个电路演示。

## 输入与输出

本项目的规则是：启用状态指示，且有构建失败或待评审请求，并且未静音时亮灯。
输入均为高有效，按 `enabled, build_failed, review_requested, muted` 排列，
行号最高位对应 `enabled`。逻辑表达式为：

```text
enabled && (build_failed || review_requested) && !muted
```

传给 `TruthSpec::new` 的输入数是 4，必须输出 1 的行是 `[10,12,14]`，
没有无关项，其余 13 行必须输出 0。行 10 为 `1010`：启用、构建未失败、
有待评审请求、未静音，所以仍应亮灯。这是软件状态的布尔教学模型，
没有连接 CI 服务或真实指示灯。

输出 SOP `1-10,11-0`，即 `enabled AND review_requested AND !muted`
或 `enabled AND build_failed AND !muted`，共 2 项、6 个文字。
POS 零模式为 `---1,-00-,0---`，即 `!muted AND (build_failed OR
review_requested) AND enabled`，共 3 子句、4 个文字。
POS 的 `0` 表示正文字、`1` 表示反文字，和 SOP 极性相反。

## 从本地源码复现

使用 [README 指定的工具链](../../README.md#build-and-test)，从仓库根目录执行：

```sh
moon -C examples/status-indicator fmt --check
moon -C examples/status-indicator check --deny-warn
moon -C examples/status-indicator run .
```

[`moon.mod`](moon.mod) 声明模块依赖 `Lyhdsba/fusekite@0.2.0`；
[`moon.pkg`](moon.pkg) 导入根包、`parts` 和 `sat`，通过 `@fusekite`、
`@parts` 和 `@sat` 调用公开 API。
[`../moon.work`](../moon.work) 同时包含库与消费者，因此按
[MoonBit 工作区规则](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html#dependency-management)
使用本地库源码，忽略依赖的注册表版本。命令无需先发布 Fusekite，
也不证明该版本在 Mooncakes 上可用。复制模块到别处时，需要建立指向库的
工作区成员路径，或另行确认并选择已发布版本。

预期输出：

```text
status indicator: enabled && (build_failed || review_requested) && !muted
SOP patterns:
  1-10
  11-0
POS zero patterns:
  ---1
  -00-
  0---
16 rows checked; SOP/POS BDD and SAT equivalent (budget 100000)
incomplete candidate rejected; SAT witness row 10 replayed
SOP gates (NOT, AND2, OR2): 1, 4, 1; packages (HC04, HC08, HC32): 1, 1, 1
```

## 断言与使用边界

[`main.mbt`](main.mbt) 先核对模式及项/子句与文字成本，再按原始业务规则
独立计算 16 行期望值，用消费者自己的 SOP 模式解释器及 POS 的
`evaluate` 逐行检查，随后要求两种形式的 BDD 和 SAT 验证均成功。
SAT 预算为 100,000 个搜索节点，`Unknown`、非法输入或反例均使等价检查失败。

负例将输入 1 行改成 `[12,14]`，故意漏掉仅有评审请求的情况；BDD 必须拒绝，
SAT 必须给出反例。消费者按最高位优先重建行号，并确认行 10 在业务规则中
为真、在错误候选中为假。它不把“成功调用 API”当成“结果正确”。

本消费者选择 SOP 直接映射并核对：共享 1 个 NOT，两个三文字乘积各用 2 个 AND2，
两项之间用 1 个 OR2，故 HC04、HC08、HC32 各需 1 片。尽管 POS 文字更少，
该消费者没有执行 POS 成本估算；库提供单独的 POS 门数与封装估算接口，且不从文字数直接推导器件成本。
修改规则时应同时更新输入表和独立期望，不能只修改预期打印文本。
断言失败会使进程失败，CI 单独运行此消费者；无需另建复制这些断言的测试。
