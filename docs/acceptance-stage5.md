# 十月验收阶段 5：Mooncakes 独立消费者

核验日期：2026-10-26（Asia/Shanghai）。起始本地 `main` 与重新 fetch 后的
`origin/main` 均为 `da53897`，远端为 `https://github.com/Lyhdsba/Fusekite.git`。
本阶段只检查已发布版本的消费，不执行发布或更改版本号。

## 实际安装与 API 执行

在仓库外新建无上级 MoonBit 工作区的项目：

```sh
moon new <temporary-directory> --user acceptance --name fusekite-registry-consumer
moon -C <temporary-directory> add Lyhdsba/fusekite
```

`moon add` 返回退出码 0，输出 `Registry index updated successfully` 和
`Downloading Lyhdsba/fusekite@0.2.0`；独立 `moon.mod` 记录
`Lyhdsba/fusekite@0.2.0`。依赖树为：

```text
acceptance/fusekite-registry-consumer@0.1.0 (local <temporary-directory>):
└─ Lyhdsba/fusekite -> Lyhdsba/fusekite@0.2.0
```

从本地只复制 [消费者 main.mbt](../examples/status-indicator/main.mbt) 与
[包导入](../examples/status-indicator/moon.pkg) 到新项目的 `cmd/main`，
未复制库源码、`examples/moon.work` 或依赖缓存。
实际通过 `moon check --deny-warn` 和 `moon run cmd/main`。
首次 `moon new` 的 Windows README 符号链接提示不影响依赖下载或执行；
下述复现脚本直接创建最小模块，不需要这个符号链接。

消费者断言核对 SOP `1-10,11-0` 与 POS `---1,-00-,0---`、全部 16 行的
独立业务规则、两种形式的 BDD/SAT 等价性（预算 100000）、故意漏行的错误
候选及 SAT 反例行 10 重放、SOP 门数 `1,4,1` 与 HC04/HC08/HC32 各 1 片。
这验证真实库 API 和结果，不只是安装命令退出成功。

## 重复执行与 CI

使用 [固定 SDK](toolchain.md)（moonc `v0.10.15+943464bfa`、Moon
`0.1.20261012`），安装 Python 3.12，在仓库根目录执行：

```sh
python -B tests/registry_consumer.py --version 0.2.0
```

[脚本](../tests/registry_consumer.py)创建仓库外的空临时模块，拒绝上级工作区，
只复制消费者代码及包导入。它刷新注册表、安装指定版本、核对下载清单的
模块名/版本、输出依赖树，然后执行 `fmt --check`、`check --deny-warn`、
`run .`，任何一步失败即失败，不使用本地源码替代。临时项目最后清理。
不要求清空全局 SDK/注册表下载缓存；消费者目录和模块依赖从空项目开始。

本轮使用 Python `3.12.14` 在 Windows 实际执行该脚本成功，注册表缓存复用
首次已下载的 `0.2.0`，格式、无警告检查及 API 断言全部通过。原有本地源码
消费者的格式、无警告检查与运行也重新通过；没有更改或重跑核心算法测试。
另用不存在的 `9999.0.0` 做失败路径检查，注册表解析报无满足版本，脚本非零
退出，未继续执行消费者或回退本地源码。

独立的 [手动 workflow](../.github/workflows/registry-consumer.yml) 接受注册表
版本参数，以相同固定 SDK 在 Ubuntu 24.04 运行脚本。它与现有
[本地源码 CI](../.github/workflows/ci.yml) 分开；后者仍运行
`moon -C examples/status-indicator ...`，没有移除或改为注册表依赖。

## 证据边界

README 的无版本安装命令本次解析到 `0.2.0`；未来最新版可能改变，重复验收
脚本显式选择版本。注册表可安装性已经本次实测，不能从旧记录中的“待发布”
推断当前仍未发布，也不能据模块元数据声称已安装。本阶段不推断发布时间、
发布者的交互过程或签名 provenance；不声称人工审阅、个人复现或硬件测试。
完整项目最终验收仍由赛事评审认定。
