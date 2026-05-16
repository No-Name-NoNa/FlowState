# Flow State

Flow State 是一个 HarmonyOS 计划与专注应用，当前产品方向是 `今天优先` 的轻量时间线：先收集任务，再安排到今天或未来，随后进入专注，最后用复盘修正计划。

当前版本是体验版。核心主流程已经可构建和体验；真机运行 QA、发布签名、真实系统提醒等能力仍需后续验证或实现。

## 当前主流程

1. 在 `收集` 快速记录暂时不排期的任务。
2. 在 `规划` 把收集箱或未来事项整理到今天。
3. 在 `今天` 查看下一步行动、今日负荷和时间线。
4. 在 `专注` 执行当前时间块并记录完成结果。
5. 在 `复盘` 查看今天或本周的计划质量。
6. 在 `设置` 调整默认专注时长、每日容量、主题和体验状态。

## 应用页面

- `TodayPage.ets`：今天主入口、下一步行动、时间线、模板和明天预备。
- `InboxPage.ets`：收集箱、快速排期、任务整理。
- `PlanPage.ets`：规划来源、自动编排、未来事项拉回今天。
- `UpcomingPage.ets`：明天、本周稍后、更晚的计划管理。
- `FocusPage.ets`：专注计时、完成记录、复盘和下一段衔接。
- `ReviewPage.ets`：今天/本周复盘、节奏图和空状态引导。
- `SettingsPage.ets`：偏好、本地数据、体验状态和能力边界。

## 关键文档

- 用户手册：`docs/USER_MANUAL.md`
- 快速指南：`docs/USER_GUIDE.md`
- 功能总表：`docs/MASTER_FEATURE_CHECKLIST.md`
- 全模块规格：`docs/FUNCTION_MODULE_SPEC.md`
- 产品与 UI 蓝图：`docs/PRODUCT_UI_BLUEPRINT.md`
- 设备 QA 清单：`docs/DEVICE_QA_CHECKLIST.md`
- 发布交付说明：`docs/RELEASE_HANDOFF.md`

## 构建

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

最新已知构建输出见：

- `flow/build/default/outputs/default/app/flow-default.hap`
- `flow/build/default/outputs/default/flow-default-unsigned.hap`

## 当前限制

- 真实系统提醒尚未接入。
- 发布签名尚未配置。
- 路由、键盘、选择器、弹层高度和小屏适配仍需真机或模拟器 QA。
- 项目/标签、自然语言输入、日历集成、桌面小组件、数据导入导出仍是后续模块。

涉及 ArkTS、ArkUI、系统提醒、日历、后台或权限能力时，后续实现应继续以 HarmonyOS 官方文档为依据：

- HarmonyOS 应用开发指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API 参考入口：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI 官方入口：https://developer.huawei.com/consumer/cn/arkui/
