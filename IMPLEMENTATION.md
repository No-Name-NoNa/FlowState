# 流序实现说明

Updated: 2026-05-19

本文记录流序当前实现结构，作为后续维护和迭代入口。

## 技术栈

- HarmonyOS
- ArkTS
- ArkUI
- Preferences 本地数据持久化
- DevEco Studio / hvigor 构建

官方参考入口：

- HarmonyOS 应用开发指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API 参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI：https://developer.huawei.com/consumer/cn/arkui/

## 页面结构

- `TodayPage.ets`：今日主入口、负荷、下一步行动、时间线、模板和明日预备。
- `InboxPage.ets`：快速收集、优先级、整理任务和日程安排。
- `PlanPage.ets`：规划来源、自动编排、建议调整和专注交接。
- `UpcomingPage.ets`：未来事项分组、移动到今天、退回收集箱和编辑。
- `FocusPage.ets`：专注计时、完成、放弃、复盘和下一段衔接。
- `ReviewPage.ets`：今日/本周复盘、计划质量、关键洞察和节奏统计。
- `SettingsPage.ets`：专注节奏、提醒偏好、主题外观、本地数据和应用状态。

## 关键工具

- `DataManager.ets`：任务、日程、专注记录和归档数据管理。
- `ThemeManager.ets`：主题 token 和外观偏好。
- `NavigationManager.ets`：统一路由和页面跳转。
- `ScheduleAnalyzer.ets`：日程冲突、负荷和时间线分析。
- `AutoPlanner.ets`：容量感知的自动编排。
- `ReviewAnalyzer.ets`：复盘洞察和节奏分析。
- `TaskDepthUtils.ets`：备注、优先级、子任务等任务深度信息。
- `LiveWindowManager.ets`：专注状态的应用内管理。

## 数据原则

- 本地数据优先。
- 任务和日程分层：任务保存内容，日程保存时间安排。
- 收集箱只展示未安排时间的任务。
- 安排后的任务仍然保留备注和子任务。
- 完成专注后冻结实际用时，复盘只补充解释。

## 交互原则

- 今天页是默认主页面。
- 每个页面只回答一个核心问题。
- 按钮必须能点击或明确呈现不可用状态。
- 详情面板优先展示标题、时间、时长和保存，深度信息按需展开。
- 专注完成后的页面层级保持浅，不重复堆叠。
- 用户文案使用产品语言，不出现开发态、测试态或内部代号。

## 构建命令

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

## 后续维护

新功能应先更新 `docs/MASTER_FEATURE_CHECKLIST.md`，实现后更新 `docs/DEVELOPMENT_PROGRESS.md`。任何用户可见文案都应保持简短、清晰、正式。
