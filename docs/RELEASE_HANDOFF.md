# 流序发布交付说明

Updated: 2026-05-19

本文记录流序 HarmonyOS 应用的交付口径、构建方式和验收范围。当前说明按正式产品交付维护。

## 当前状态

- 产品名称：流序
- 当前版本：1.0
- 主分支工作分支：`ksy`
- 核心闭环：收集、安排、专注、复盘、设置、本地数据
- 应用图标：`flow/src/main/resources/base/media/startIcon.png`
- 构建产物：
  - `flow/build/default/outputs/default/app/flow-default.hap`
  - `flow/build/default/outputs/default/flow-default-unsigned.hap`

## 构建命令

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

## 交付范围

- Today-first 主入口。
- Inbox 快速收集与任务整理。
- Plan 自动编排与未来事项移入今天。
- Upcoming 分组管理未来安排。
- Focus 专注计时、完成记录和下一段衔接。
- Review 今日/本周复盘、计划质量与关键洞察。
- Settings 专注节奏、提醒偏好、主题外观、本地数据和应用状态。
- 本地数据迁移与启动初始化保护。
- 用户手册和快速指南。

## 验收重点

1. 应用启动后默认进入 `今天`。
2. 收集任务后可以安排到今天、明天或指定日期。
3. 今天时间线可以进入专注、完成、复盘并继续下一段。
4. 未来事项可以移动到今天或退回收集箱。
5. 复盘页可以查看今日和本周节奏。
6. 设置页主题、专注节奏和偏好文案保持一致。

## 官方文档入口

- HarmonyOS 应用开发指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API 参考入口：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI 官方入口：https://developer.huawei.com/consumer/cn/arkui/
