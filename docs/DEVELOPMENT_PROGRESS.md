# Flow State HarmonyOS Development Progress

## Working Rules

- Branch: `ksy`
- Target: HarmonyOS mobile app, ArkTS + ArkUI.
- Official context: read `docs/ARKTS_OFFICIAL_CONTEXT.md` before ArkTS/ArkUI changes.
- Feature source: `副本任务类功能.xlsx`.
- Verification command:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

## Official Docs Checked

- HarmonyOS application knowledge map: https://developer.huawei.com/consumer/cn/app/knowledge-map/
- ArkUI overview: https://developer.huawei.com/consumer/cn/arkui/
- ArkTS overview: https://developer.huawei.com/consumer/cn/arkts/
- Stage model overview: https://developer.huawei.com/consumer/cn/arkui/arkui-stage/
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api

## Product Roadmap

- Detailed product backlog and phased feature roadmap: `docs/PRODUCT_ROADMAP.md`
- Roadmap inputs: `副本任务类功能.xlsx`, current implementation state, and market references including TickTick, Todoist, Microsoft To Do, Any.do, Structured, Sunsama, Taskito, and Sorted.
- Next recommended phase: Phase 4 UI refinement, focused on "简约而不简单" rather than adding backend-heavy features immediately.

## Feature Backlog From XLSX

| Module | Feature | Status | Notes |
| --- | --- | --- | --- |
| 时间设置 | 精确时间 | Done in Phase 2 | Schedules now store date, time, and computed due timestamp. |
| 时间设置 | 区间时间 | Partial | Current "进行中" is derived from due time minus estimated duration; richer date ranges still pending. |
| 提醒机制 | 闹钟提醒 | Pending | Needs a separate official system capability and permission review before implementing real OS alarms. |
| 提醒机制 | 自定义提醒 | Partial | UI/data supports no reminder, on time, 10 min before, 30 min before. Rule engine pending. |
| 任务操作 | 延后/提前 | Pending | Next phase candidate. |
| 任务操作 | 变更备注 | Pending | Should be paired with postpone/advance. |
| 状态展示 | 进行中标识 | Done in Phase 2 | Schedules show 已安排 / 进行中 / 已过期. |
| 状态展示 | 优先级排序 | Done in Phase 2 | Tasks and schedules are sorted by due time, then priority. |

## Phase 1: Cold Fresh UI Polish

Status: Done

- Replaced warm yellow/orange visual blocks with a colder blue, teal, and white-glass palette.
- Reworked the task page into a plan workbench instead of a sparse list.
- Improved records page with calmer statistics and ring-style visual rhythm.
- Removed low-value placeholder surfaces, including the fake login page and empty AI planning card.

Verification:

- `assembleApp` passed before Phase 2 changes.

## Phase 2: Time Planning And Schedule Awareness

Status: Done

Files changed:

- `flow/src/main/ets/models/DataModels.ets`
- `flow/src/main/ets/pages/TaskPage.ets`

Implemented:

- Added schedule fields: `scheduledDate`, `scheduledTime`, `dueAt`, `reminderMinutes`.
- Added quick date choices for today, tomorrow, and the next several days.
- Added time point choices: 09:00, 12:00, 15:00, 18:00, 20:00.
- Added reminder choices: no reminder, on time, 10 minutes before, 30 minutes before.
- Let "add task" create the first executable schedule directly, matching the user's mental model better than creating an empty task first.
- Let "add schedule" choose date, time, and reminder.
- Added schedule status chips: 已安排, 进行中, 已过期.
- Added summary metrics for tasks, ongoing schedules, overdue schedules, and planned minutes.
- Sorted schedule lists by due time and task lists by nearest due time plus priority.

Verification:

- Passed on 2026-05-12:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 20 s 865 ms`.

Known warnings:

- Existing deprecated `router.pushUrl`, `router.back`, and `router.getState` usages.
- Existing `@Entry export struct` preview warning.
- Signing config is not configured for this local build.

## Phase 3: Product-Level Visual Restructure

Status: Done

Files changed:

- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/ets/pages/HomePage.ets`
- `flow/src/main/ets/pages/TaskPage.ets`
- `flow/src/main/ets/pages/RecordsPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/SettingsPage.ets`
- `flow/src/main/ets/components/common/GlassCard.ets`
- `flow/src/main/resources/base/element/color.json`
- `flow/src/main/resources/base/element/float.json`
- `flow/src/main/resources/base/element/string.json`
- `flow/src/main/ets/utils/Constants.ets`

Implemented:

- Rebuilt the app around a restrained productivity palette: fog white surfaces, graphite text, deep blue primary actions, and muted teal status accents.
- Removed visible AI placeholder surfaces and leftover login/string resources that made the app feel like a demo.
- Reduced card radius and visual noise, replacing the older scattered glass/yellow feeling with tighter panels and clearer hierarchy.
- Reworked the home page into a focused daily dashboard: today's status, mood calibration, rhythm summary, and two useful actions.
- Reworked the task page into a clean planning workbench: overview metrics, compact task cards, inline schedules, and consistent creation dialogs.
- Reworked records into a small analytics dashboard: summary ring, mood distribution, mood trend, and recent focus history.
- Reworked focus mode into a dark immersive timer surface.
- Reworked settings into four useful groups: focus rhythm, reminder feedback, appearance, and about.
- Reworked the bottom tab navigation to match the new visual language.

Verification:

- Passed on 2026-05-12:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 18 s 469 ms`.

## Phase 4: Next Action, Inbox, And Timeline Foundation

Status: Partial

Files changed:

- `flow/src/main/ets/pages/HomePage.ets`
- `flow/src/main/ets/pages/TaskPage.ets`
- `docs/PRODUCT_ROADMAP.md`

Implemented:

- Added a home-page next-action card that finds the nearest upcoming schedule and starts the linked focus session directly.
- Added daily schedule load metrics on Home so the dashboard is less decorative and more decision-oriented.
- Added quick task capture on the Task page. A one-line task can now be saved without opening the full creation dialog.
- Added Inbox counting for unscheduled tasks, aligning quick capture with the planned Inbox model.
- Added a Today timeline preview that displays today's scheduled time blocks in chronological order.
- Updated the roadmap status for Today dashboard, planning workbench, Inbox, quick add, Inbox capture, and daily timeline.

Verification:

- Passed on 2026-05-12:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 31 s 264 ms`.

## Phase 5: Task Detail Sheet And Inbox Scheduling

Status: Partial

Files changed:

- `flow/src/main/ets/models/DataModels.ets`
- `flow/src/main/ets/pages/TaskPage.ets`
- `docs/PRODUCT_ROADMAP.md`

Implemented:

- Added optional task detail fields: `note`, `steps`, and `updatedAt`.
- Added a task detail bottom sheet so task cards stay visually clean while deeper controls are available on demand.
- Added editing for task title and priority after creation.
- Added persisted task notes.
- Added checklist-style subtasks with add, toggle, and delete actions.
- Added scheduling from the detail sheet, so an Inbox task can be turned into a concrete time block without going through the full new-task dialog.
- Updated roadmap status for task detail sheet, Inbox capture, title/priority editing, subtasks, and notes.

Verification:

- Passed on 2026-05-12:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 26 s 851 ms`.

## Next Phase Candidates

1. Implement delay/advance with a mandatory change note and visible change history.
2. Add a dedicated Inbox section/filter so unscheduled tasks can be triaged faster.
3. Add schedule editing for existing time blocks, not only adding new ones.
4. Expand time planning from quick time points to a true picker-style time input after official component/API confirmation.
5. Implement real reminder delivery after confirming the official HarmonyOS system capability, permission, and background execution model.
6. Continue records page analytics with task completion distribution and focus-time charts.
