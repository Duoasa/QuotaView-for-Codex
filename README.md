<p align="center">
  <img src="plugins/quotaview/assets/logo.png" width="128" alt="QuotaView for Codex logo">
</p>

<h1 align="center">QuotaView for Codex</h1>

<p align="center">
  <a href="#readme-zh-cn">简体中文</a> ·
  <a href="#readme-en">English</a>
</p>

<a id="readme-zh-cn"></a>

## 简体中文

### 安装（无需打开终端）

普通用户不需要手动执行安装命令。将下方提示词完整复制到一个新的 Codex 聊天窗口，
Codex 会使用内置的插件管理命令添加此 Git Marketplace 并安装插件。

> 本项目是第三方自定义 Git Marketplace，不是 OpenAI 官方插件市场条目。安装过程不会
> 绕过 Codex 的命令审批、Hook 信任或 macOS 目录授权；这些安全确认仍由你本人完成。

#### 第 1 步：确认运行环境

安装前请确认：

- 已安装支持插件与 Hooks 的 Codex；
- 已通过 Codex 官方登录完成登录；
- 使用 macOS 14 或更高版本；
- 已安装 QuotaView，或其他支持 QuotaView Bridge Protocol v1 的兼容软件。

本插件不是 OpenAI 官方插件，不会绕过 Codex 的审批、Hook 信任或沙盒机制。

#### 第 2 步：将安装提示词发送给 Codex

复制下面的完整提示词，粘贴到 Codex 聊天窗口并发送：

```text
请直接帮我安装 QuotaView for Codex 插件，不要只提供操作说明，也不要让我打开终端。

安装目标：
- Git Marketplace：Duoasa/QuotaView-for-Codex
- 插件：quotaview@quotaview-preview

请按以下要求执行并验证：
1. 使用 Codex 内置的插件管理命令检查该 Marketplace 是否已经配置。
2. 如果尚未配置，添加 Duoasa/QuotaView-for-Codex；如果已经存在，先刷新它的 Git Marketplace 快照。
3. 检查 quotaview@quotaview-preview 是否已经安装。如果尚未安装，直接安装；如果已经安装，不要卸载、重装或删除数据，只报告当前状态和版本。
4. 只使用 codex plugin 与 codex plugin marketplace 提供的命令。不要手工编辑 ~/.codex，不要手动复制插件文件，也不要绕过 Hooks 信任。
5. 安装后确认 Codex 能识别 QuotaView for Codex，并报告插件版本。不要读取或输出登录凭据、插件数据内容或完整本地路径。
6. 最后明确告诉我安装是否成功、是否需要重启 Codex，以及重启后如何在设置中完成 Hooks 的 Review / Trust all。Hooks 信任必须由我本人确认。

如果执行命令或访问 GitHub 需要授权，请直接发起对应的授权请求，等待我确认后继续。
```

Codex 可能会弹出命令执行或网络访问授权。确认它正在执行 Codex 自带的插件管理操作后，
再批准并让它继续。安装完成后，完全退出并重新打开 Codex。

#### 第 3 步：授权 Hooks

在 Codex 中打开：

1. `设置 → 插件 → QuotaView for Codex`；
2. 展开 `Hooks`；
3. 点击 `检查 / Review`；
4. 选择 `全部信任 / Trust all`。

如果没有看到“全部信任”，请进入 `设置 → Hooks`，确认以下 Hook 均已启用并显示为
`trusted`：

- `SessionStart`
- `SessionEnd`
- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `Stop`

授权完成后，再次完全退出并重新打开 Codex，使 `SessionStart` 生效。

#### 第 4 步：连接客户端软件

QuotaView 用户可以在 Codex 中发送：

```text
Connect QuotaView to Codex.
```

Codex 会调用插件的配对流程并打开 QuotaView。请在 macOS 文件选择器中确认 Codex
显示的 `PLUGIN_DATA` 文件夹，只授予 QuotaView 只读访问权限。

其他兼容软件可以读取同一份 Bridge Protocol v1 本地数据。具体连接界面由客户端实现，
但必须由用户明确选择并授权插件数据目录；客户端不应读取 Codex 登录凭据或修改 Codex
配置。

#### 第 5 步：确认连接

在 Codex 中开始一个新任务，随后在客户端检查：

- 插件版本是否显示为 `1.0.0-preview.7`；
- 是否已收到新的用量快照；
- 是否出现新的生命周期事件；
- 任务结束后是否收到 `Stop`。

也可以在 Codex 中发送：

```text
Check my QuotaView plugin connection.
```

### 这个插件是做什么的

QuotaView for Codex 是一个开源、本地优先、只读的 Codex 数据桥。它通过 Codex 官方
只读 app-server 方法获取经过筛选的用量信息，并通过受支持的 Codex Hooks 记录脱敏的
任务生命周期事件。

QuotaView 是该协议的参考客户端，但插件并不限定只能服务 QuotaView。任何遵循 Bridge
Protocol v1、获得用户明确目录授权的兼容 macOS 软件，都可以读取同一份本地数据，构建
自己的菜单栏工具、用量面板、Widget、灵动岛、任务状态视图或通知体验。

因此它的定位是面向同类软件的基础数据提供插件：只负责稳定地产生数据，不规定客户端
必须如何展示数据。

### 包含哪些功能

- **脱敏用量快照**：方案类型、主要额度窗口、已用比例、窗口时长、重置时间、普通
  Credits 状态、额度受限状态、累计 Token 和最新的每日 Token 桶。
- **任务活动事件**：`SessionStart`、`SessionEnd`、`UserPromptSubmit`、
  `PreToolUse`、`PostToolUse` 和 `Stop`。
- **自动刷新**：`SessionStart` 与 `Stop` 会在上一份用量快照超过五分钟时请求新快照；
  高频事件会合并到五分钟窗口内。
- **手动强制刷新**：可以通过插件命令立即请求新的脱敏用量快照。
- **本地数据协议**：提供版本化的桥接清单、健康状态、用量快照和单调递增的事件文件。
- **隐私保护**：不保存提示词、命令文本、工具输入输出、文件内容、模型回复、推理、
  账号标识、邮箱、Token、Cookie、凭据或原始 app-server 响应。

### 通过这个插件你能做什么

作为普通用户，你可以让兼容客户端：

- 展示 Codex 当前额度、重置时间和历史用量；
- 在 Codex 开始任务、调用工具或结束任务时更新实时状态；
- 在菜单栏、桌面 Widget 或灵动岛中显示统一的任务状态；
- 在不交出 Codex 登录凭据的情况下，让本地软件读取必要状态；
- 检查连接、解释本地保存的数据，或执行一次明确的强制刷新。

作为开发者，你可以基于 Bridge Protocol v1：

- 构建新的 Codex 用量查看器或状态面板；
- 将同一份脱敏事件流接入自己的 macOS 客户端；
- 复用稳定的本地文件协议，而不需要读取 Codex 内部数据库；
- 在客户端中自行实现状态归并、通知、历史记录和可视化。

### 数据契约

插件在自己的数据目录中写入：

- `bridge.json`：协议、插件版本和安装标识；
- `status.json`：最近成功写入时间和桥接健康状态；
- `usage.json`：经过白名单筛选的用量快照；
- `events/*.json`：按序号递增的脱敏生命周期事件。

事件只包含会话与 Turn 的单向哈希、工作区最后一级文件夹名称、粗粒度工具类别、事件
类型、时间戳、协议版本、安装标识和桥接健康信息。最新事件超过 512 条后会自动轮换。

详见 [PRIVACY.md](PRIVACY.md) 和 [SECURITY.md](SECURITY.md)。

### 卸载

1. 先在 QuotaView 或其他客户端中断开插件数据目录；
2. 再在 Codex 中禁用或卸载 `quotaview`；
3. 插件不会代替用户删除数据目录，也不会修改其他 Codex 设置。

### 参与开发与发布

发布流程见 [RELEASING.md](RELEASING.md)。候选版本需要完成隔离安装、卸载、重装、
桥接测试和资源一致性检查；固定 Tag 的源码资产必须可以重复构建并得到一致结果。

<p align="right"><a href="#readme-zh-cn">返回中文顶部</a> · <a href="#readme-en">English</a></p>

---

<a id="readme-en"></a>

## English

### Installation (no Terminal required)

Regular users do not need to run installation commands manually. Copy the complete prompt below
into a new Codex chat. Codex will use its built-in plugin-management commands to add this Git
Marketplace and install the plugin.

> This project is a third-party custom Git Marketplace, not an official OpenAI Marketplace
> listing. Installation does not bypass command approval, Hook trust, or the macOS folder picker;
> you remain in control of those security confirmations.

#### Step 1: Check the requirements

Before installing, make sure that:

- Codex supports plugins and Hooks;
- you are signed in through official Codex;
- you are running macOS 14 or later;
- QuotaView, or another client compatible with QuotaView Bridge Protocol v1, is installed.

This is not an official OpenAI plugin. It does not bypass Codex approvals, Hook trust, or
sandboxing.

#### Step 2: Send the installation prompt to Codex

Copy and send this complete prompt in a Codex chat:

```text
Install QuotaView for Codex for me directly. Do not only explain the steps, and do not ask me to open Terminal.

Installation targets:
- Git Marketplace: Duoasa/QuotaView-for-Codex
- Plugin: quotaview@quotaview-preview

Execute and verify the installation with these requirements:
1. Use Codex's built-in plugin-management commands to check whether this Marketplace is already configured.
2. If it is missing, add Duoasa/QuotaView-for-Codex. If it already exists, refresh its Git Marketplace snapshot first.
3. Check whether quotaview@quotaview-preview is already installed. Install it if it is missing. If it is already installed, do not uninstall, reinstall, or delete data; only report its current status and version.
4. Use only commands provided by codex plugin and codex plugin marketplace. Do not edit ~/.codex manually, copy plugin files manually, or bypass Hook trust.
5. After installation, verify that Codex recognizes QuotaView for Codex and report the plugin version. Do not read or print credentials, plugin data contents, or full local paths.
6. Finally, clearly tell me whether installation succeeded, whether Codex must restart, and how to complete Hooks Review / Trust all in Settings after restart. I must personally approve Hook trust.

If command execution or GitHub access requires approval, request that approval directly and wait for me to confirm before continuing.
```

Codex may request permission to execute commands or access the network. Approve only after confirming
that it is performing Codex's built-in plugin-management operations. Quit Codex completely and
reopen it after installation.

#### Step 3: Trust the Hooks

In Codex:

1. Open `Settings → Plugins → QuotaView for Codex`.
2. Expand `Hooks`.
3. Select `Review`.
4. Select `Trust all`.

If `Trust all` is not available, open `Settings → Hooks` and verify that each of these Hooks is
enabled and marked `trusted`:

- `SessionStart`
- `SessionEnd`
- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `Stop`

Quit and reopen Codex once more after trusting the Hooks so `SessionStart` can run.

#### Step 4: Connect a client

QuotaView users can send this prompt in Codex:

```text
Connect QuotaView to Codex.
```

Codex runs the pairing flow and opens QuotaView. In the macOS folder picker, confirm the
`PLUGIN_DATA` folder shown by Codex and grant QuotaView read-only access.

Other compatible applications can consume the same local Bridge Protocol v1 data. Their pairing
interface is client-defined, but the user must explicitly select and authorize the plugin data
directory. A client should never read Codex credentials or modify Codex configuration.

#### Step 5: Verify the connection

Start a new Codex task, then check the client for:

- plugin version `1.0.0-preview.7`;
- a new usage snapshot;
- new lifecycle events;
- a `Stop` event after the task completes.

You can also send:

```text
Check my QuotaView plugin connection.
```

### What this plugin does

QuotaView for Codex is an open-source, local-first, read-only Codex data bridge. It uses official
Codex read-only app-server methods to obtain an allowlisted usage projection and supported Codex
Hooks to record sanitized task lifecycle events.

QuotaView is the reference client, but the plugin is not limited to QuotaView. Any compatible
macOS application that implements Bridge Protocol v1 and receives explicit directory access from
the user can consume the same local data to build a menu bar utility, quota dashboard, Widget,
Dynamic Island, task-status view, or notification experience.

Its role is a foundational data provider for this category of software: it produces stable data
without dictating how clients must present it.

### Features

- **Sanitized usage snapshots:** plan type, primary rate window, used percentage, window duration,
  reset time, normal Credits state, limit state, lifetime tokens, and the newest daily token bucket.
- **Task activity events:** `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `PreToolUse`,
  `PostToolUse`, and `Stop`.
- **Automatic refresh:** `SessionStart` and `Stop` request a new snapshot when the previous one is
  at least five minutes old; frequent events are merged into the same five-minute window.
- **Explicit forced refresh:** a plugin command can request a fresh sanitized usage snapshot.
- **Local data protocol:** versioned bridge metadata, health state, usage snapshots, and monotonic
  event files.
- **Privacy by design:** no prompts, command text, tool input or output, file contents, model
  responses, reasoning, account identifiers, email, tokens, cookies, credentials, or raw
  app-server responses are stored.

### What you can build or do with it

As a user, a compatible client can:

- display current Codex quota, reset time, and usage history;
- update live state when Codex starts a task, uses a tool, or completes a task;
- present the same task state in a menu bar, desktop Widget, or Dynamic Island;
- read the minimum required local state without receiving Codex credentials;
- diagnose the connection, explain stored data, or request an explicit forced refresh.

As a developer, Bridge Protocol v1 lets you:

- build a new Codex usage viewer or status dashboard;
- integrate the sanitized event stream into another macOS client;
- reuse a stable local file contract without reading Codex internal databases;
- implement client-side state reduction, notifications, history, and visualization.

### Data contract

The plugin writes these files inside its own data directory:

- `bridge.json`: protocol, plugin version, and installation identity;
- `status.json`: latest successful write and bridge health;
- `usage.json`: the allowlisted usage snapshot;
- `events/*.json`: monotonic sanitized lifecycle events.

Events contain only one-way session and turn hashes, the final workspace folder name, a coarse tool
category, event type, timestamp, protocol version, installation identity, and bridge health
metadata. Events rotate after the newest 512 records.

See [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md).

### Uninstall

1. Disconnect the plugin data directory in QuotaView or another client.
2. Disable or uninstall `quotaview` in Codex.
3. The plugin does not delete the data directory or modify unrelated Codex settings.

### Contributing and releases

See [RELEASING.md](RELEASING.md). Candidate validation covers isolated installation,
uninstallation, reinstallation, bridge tests, and asset consistency. Fixed-tag source assets must
be reproducible.

<p align="right"><a href="#readme-en">Back to English top</a> · <a href="#readme-zh-cn">简体中文</a></p>
