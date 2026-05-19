# 流序

流序是一款面向 HarmonyOS 的计划与专注应用。它把一天整理成清晰的时间线：先快速收集想法，再安排到今天或未来，随后进入专注，最后用复盘校准节奏。

产品主线是“让事情入序，而不是让清单堆满”。应用优先服务每天真实会发生的流程：捕捉、安排、执行、复盘。

## 核心流程

1. 在 `收集` 中快速记下想法、任务或待办。
2. 在 `规划` 中把收集箱或未来事项整理到合适的时间。
3. 在 `今天` 中查看今日负荷、下一步行动和完整时间线。
4. 在 `专注` 中执行当前时间块，记录完成结果。
5. 在 `复盘` 中查看计划质量、专注节奏和调整记录。
6. 在 `设置` 中管理专注节奏、每日容量、提醒偏好、主题和本地数据。

## 页面结构

- `TodayPage.ets`：今日主入口、负荷概览、下一步行动、时间线、常用模板和明日预备。
- `InboxPage.ets`：收集箱、快速收集、任务整理和日程安排。
- `PlanPage.ets`：规划来源、自动编排、未来事项前移和今日顺序确认。
- `UpcomingPage.ets`：明天、本周稍后和更远安排的管理。
- `FocusPage.ets`：专注计时、完成记录、复盘衔接和下一段流转。
- `ReviewPage.ets`：今日/本周复盘、计划质量、节奏洞察和变更记录。
- `SettingsPage.ets`：偏好设置、本地数据、主题外观和应用状态。

## 关键文档

- 用户手册：`docs/USER_MANUAL.md`
- 快速指南：`docs/USER_GUIDE.md`
- 功能总表：`docs/MASTER_FEATURE_CHECKLIST.md`
- 全模块规格：`docs/FUNCTION_MODULE_SPEC.md`
- 产品与 UI 蓝图：`docs/PRODUCT_UI_BLUEPRINT.md`

## 构建

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

构建产物：

- `flow/build/default/outputs/default/app/flow-default.hap`
- `flow/build/default/outputs/default/flow-default-unsigned.hap`

## 技术栈

- HarmonyOS
- ArkTS
- ArkUI
- 本地数据持久化
- 时间线规划与专注记录

## 官方参考

- HarmonyOS 应用开发指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API 参考入口：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI 官方入口：https://developer.huawei.com/consumer/cn/arkui/
