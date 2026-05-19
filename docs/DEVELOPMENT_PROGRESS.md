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
- Product and UI reset blueprint: `docs/PRODUCT_UI_BLUEPRINT.md`
- Authoritative full module specification: `docs/FUNCTION_MODULE_SPEC.md`
- Roadmap inputs: `副本任务类功能.xlsx`, current implementation state, and market references including TickTick, Todoist, Microsoft To Do, Any.do, Structured, Sunsama, Taskito, and Sorted.
- Next recommended phase: continue launch-ready UI and copy polish from `docs/MASTER_FEATURE_CHECKLIST.md`.

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

Status: Done

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

## Phase 6: Product And UI Reset Blueprint

Status: Done

Files changed:

- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a detailed product/UI reset blueprint that explicitly moves Flow State away from the old Home / Task / Records structure.
- Extracted reference-app patterns from TickTick, Structured, Sunsama, Any.do, and Todoist.
- Defined the next target information architecture: Today / Inbox / Plan / Review.
- Defined the target visual language: Fresh Graphite Timeline with semantic accents instead of a single-color interface.
- Defined target screens, core feature priorities, implementation stages, and acceptance criteria.

## Phase 7: Navigation Reset To Timeline-First IA

Status: Partial

Files changed:

- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/resources/base/profile/main_pages.json`

Implemented:

- Replaced the old primary navigation model with Today / Inbox / Plan / Review.
- Added a new Today surface that starts from workload, next action, timeline blocks, and an Inbox strip.
- Added a dedicated Inbox surface for fast capture and unscheduled task triage.
- Added a Plan surface that frames daily planning as a five-step ritual: review, choose, estimate, order, start.
- Added a Review surface that starts with narrative interpretation before metrics.
- Kept old Home / Task / Records files in place temporarily for migration safety, but they are no longer the root tab model.

Verification:

- Passed on 2026-05-12:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 18 s 449 ms`.

## Phase 8: Full Module Spec And First Interaction Fixes

Status: Partial

Files changed:

- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/DEVELOPMENT_PROGRESS.md`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`

Implemented:

- Added `docs/FUNCTION_MODULE_SPEC.md` as the authoritative product/module context for future implementation.
- Detailed every major module: Today, Inbox, Plan, Task Detail, Focus, Review, Schedule Editing, Reminder Engine, Projects/Tags, Routines, Settings, and Data/Migration.
- Defined user goals, core data, required functions, UI description, and acceptance criteria for each module.
- Fixed the first batch of non-functional interactions:
  - Today's empty-state Plan action now opens Inbox.
  - Today Inbox preview rows open Inbox.
  - Inbox items can be scheduled to today or tomorrow.
  - Plan step buttons route to Review, Inbox, or Today.

Verification:

- Passed on 2026-05-12:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 16 s 787 ms`.

## Phase 9: Structured-Style Timeline Editing And Inbox Triage

Status: Partial

Files changed:

- `flow/src/main/ets/models/DataModels.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added schedule change history fields to the data model, including change type, note, before/after due time, and before/after duration.
- Reworked Today into a more alive timeline surface:
  - Current-time indicator.
  - Free-space rows between planned blocks.
  - Start/end time display for each block.
  - Ongoing/past/upcoming status chips.
  - Empty timeline action that opens Inbox.
- Added a schedule editing bottom sheet from Today timeline blocks:
  - Edit title.
  - Change duration.
  - Select date and time chips.
  - Add change notes.
  - Advance 15 minutes.
  - Delay 30 minutes.
  - Move to tomorrow 09:00.
  - Delete the block.
- Reworked Inbox into a more complete triage surface:
  - Quick capture remains one-line.
  - Each Inbox item has Today, Tomorrow, and Triage actions.
  - Triage sheet can edit title, note, priority, duration, date, and time.
  - Inbox task can be converted into a custom timeline block.
  - Inbox task can be deleted.

Verification:

- Passed on 2026-05-14:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 50 s 701 ms`.

Known warnings:

- Existing deprecated `router.pushUrl`, `router.back`, and `router.getState` usages remain.
- Existing `@Entry export struct` preview warning remains.
- Signing config is not configured for this local build.

## Phase 10: Execution State And Real Review Signals

Status: Partial

Files changed:

- `flow/src/main/ets/models/DataModels.ets`
- `flow/src/main/ets/utils/Constants.ets`
- `flow/src/main/ets/utils/DataManager.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added schedule execution state fields: planned, completed, deferred, and cancelled.
- Added actual minutes, completion time, deferral time, cancellation time, and state note fields for schedules.
- Added schedule archive storage so deleted time blocks can still be reviewed later.
- Today now supports marking a time block completed from the edit sheet.
- Deleted Today time blocks are archived before removal.
- Focus completion now marks the linked schedule as completed and stores actual focus minutes on that schedule.
- Inbox-created schedule blocks now initialize as planned blocks.
- Review now reads real schedule data instead of placeholder future ideas:
  - Completed schedule blocks.
  - Relevant planned blocks.
  - Delay, advance, edit, and delete counts.
  - Estimate accuracy from actual minutes vs planned minutes.
  - Recent change feed from schedule change history and deleted-block archive.

Verification:

- Passed on 2026-05-14:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 36 s 516 ms`.

Known warnings:

- Existing deprecated `router.pushUrl`, `router.back`, and `router.getState` usages remain.
- Existing `@Entry export struct` preview warning remains.
- Signing config is not configured for this local build.

## Phase 11: Interactive Planning And Focus Surface Upgrade

Status: Partial

Files changed:

- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Turned Plan from a static ritual list into an interactive planning surface:
  - Five-step clickable stepper.
  - Active-step decision panel.
  - Real primary and secondary actions.
  - Schedule the top Inbox task into today's timeline.
  - Workload progress and status remain visible during planning.
  - Today preview shows the first planned time blocks.
- Upgraded Focus from a plain timer into a more polished execution page:
  - Linked task and schedule context.
  - Dark graphite execution surface.
  - Larger ring timer with clearer remaining/elapsed state.
  - Primary Start/Pause/Continue control.
  - Secondary Complete and Abandon actions.
  - Rhythm strip for planned minutes, elapsed minutes, and pause count.
  - Cleaner completion reflection sheet.

Verification:

- Passed on 2026-05-14:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 47 s 401 ms`.

Known warnings:

- Existing deprecated `router.pushUrl`, `router.back`, and `router.getState` usages remain.
- Existing `@Entry export struct` preview warning remains.
- Signing config is not configured for this local build.

## Phase 12: Missed Block Carry-Over

Status: Partial

Files changed:

- `flow/src/main/ets/models/DataModels.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added `carryover` as a schedule change type.
- Today now detects missed blocks: planned blocks whose end time has passed and that are not completed, cancelled, or already deferred.
- Added a missed-block banner on Today with two real actions:
  - Carry all missed blocks to tomorrow.
  - Open Review before deciding.
- Carry-over now preserves history:
  - Original missed block becomes deferred in today's timeline.
  - A new planned block is created for tomorrow.
  - A carry-over change record stores before/after due time and duration.
- Plan now reads tomorrow carry-over blocks:
  - Shows a tomorrow carry-over panel.
  - Shows carried-over minutes before more tasks are added.
  - Step 3 guidance changes when tomorrow already has carried-over work.
- Review treats carry-over as a reviewable planning change.

Verification:

- Passed on 2026-05-14:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 51 s 432 ms`.

Known warnings:

- Existing deprecated `router.pushUrl`, `router.back`, and `router.getState` usages remain.
- Existing `@Entry export struct` preview warning remains.
- Signing config is not configured for this local build.

## Phase 13: Settings-Driven Capacity And Default Scheduling

Status: Partial

Files changed:

- `flow/src/main/ets/models/DataModels.ets`
- `flow/src/main/ets/utils/DataManager.ets`
- `flow/src/main/ets/pages/SettingsPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/TaskPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added `dailyCapacityMinutes` to user settings.
- Added default-setting normalization in `DataManager.getUserSettings()` so older saved settings keep working.
- Settings now exposes a daily capacity row and clamps it to 60-720 minutes.
- Today workload band now reads the configured daily capacity instead of a hardcoded 300-minute target.
- Plan workload status now uses the same configured capacity and treats 70% as the near-limit threshold.
- Plan auto-scheduling uses the configured default focus duration.
- Inbox quick scheduling and triage default to the configured focus duration.
- Task detail/add-schedule flows now use the configured focus duration as the fallback.
- Standalone Focus sessions now default to the configured focus duration when no linked schedule duration is passed.

Verification:

- Passed on 2026-05-14:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 17 s 505 ms`.

Known warnings:

- Existing deprecated `router.pushUrl`, `router.back`, and `router.getState` usages remain.
- Existing `@Entry export struct` preview warning remains.
- Signing config is not configured for this local build.

## Phase 14: Timeline Conflict Detection

Status: Partial

Files changed:

- `flow/src/main/ets/utils/ScheduleAnalyzer.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a shared schedule analyzer for active-block overlap detection.
- Today now detects overlapping active time blocks after loading the current timeline.
- Today shows a conflict banner with the first overlap and a direct action to open the conflicting block editor.
- Conflicting timeline blocks now get a coral status chip and border.
- The schedule edit sheet now warns when the candidate date/time/duration will overlap another active block.
- Plan now includes conflict count in workload metrics.
- Plan shows a dedicated conflict panel with overlap time, affected block titles, overlap minutes, and a route to Today.
- Plan step guidance now tells users to resolve timeline conflicts before continuing.

Verification:

- Passed on 2026-05-14:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

Result: `BUILD SUCCESSFUL in 1 min 47 s 969 ms`.

Known warnings:

- Existing deprecated `router.pushUrl`, `router.back`, and `router.getState` usages remain.
- Existing `@Entry export struct` preview warning remains.
- Signing config is not configured for this local build.

## Phase 15: Picker-Style Date And Time Input

Status: Done

Files changed:

- `flow/src/main/ets/utils/PickerDateTime.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a shared `PickerDateTime` helper for picker date/time conversion.
- Today schedule editing now uses native `DatePicker` and `TimePicker` controls for date and end-time selection.
- Inbox triage now uses native `DatePicker` and `TimePicker` controls for custom scheduling.
- Removed the practical limitation where custom scheduling depended on a few fixed time chips.
- Kept conflict detection connected to picker changes, so overlap warnings update when date, time, or duration changes.
- Updated the module spec to treat picker-style scheduling as the target interaction.

Verification:

- `git diff --check` passed on 2026-05-14 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 16: Capacity-Aware Auto Planning

Status: Done

Files changed:

- `flow/src/main/ets/utils/AutoPlanner.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a pure `AutoPlanner` helper that produces Today suggestions from Inbox tasks.
- Suggestions respect the Settings daily capacity, the Settings default focus duration, task priority, existing active timeline blocks, and usable free windows.
- Plan now shows an Auto Plan panel with suggested start/end windows, priority, duration reason, remaining capacity after applying, and a real action button.
- Plan primary action can apply all generated suggestions when the planning step is on selection.
- Applying suggestions persists multiple `Schedule` records and reloads Today planning state.
- Conflict state blocks auto-planning and routes the user back to Today to fix overlaps first.

Verification:

- `git diff --check` passed on 2026-05-14 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation outside the new Plan helper, one centralized Plan router deprecation warning, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 17: Entry Flow And Inbox Feedback

Status: Done

Files changed:

- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `docs/USER_GUIDE.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Bottom navigation now uses clearer Chinese labels: Today is presented as `今天`, with `收集`, `规划`, and `复盘`.
- Today header now explains the product model in one sentence: arrange work into a timeline and execute one block at a time.
- Today empty state now includes a compact three-step flow: collect, arrange, focus.
- Inbox quick scheduling now shows a feedback banner after `今天`, `明天`, or custom scheduling, so scheduled tasks no longer appear to disappear silently.
- Inbox empty state now explains that it only contains unscheduled tasks.
- Today now loads and displays a `明天预备` section for tomorrow's scheduled blocks, making `明天` scheduling visible before the next day.
- Added `docs/USER_GUIDE.md` as a short operating guide for the current app workflow.

Verification:

- `git diff --check` passed on 2026-05-14 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 18: Concrete App Framework

Status: Done

Files changed:

- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a concrete app framework that defines the product spine, main information architecture, page responsibilities, domain model framework, technical architecture, UI rules, and phased implementation roadmap.
- Locked the next major build phase to `Future And Schedule Ownership`, because it directly solves the ambiguity around tasks scheduled for tomorrow or later.
- Added `Future` as a planned module in the full module specification.
- Clarified that `APP_FRAMEWORK.md`, `FUNCTION_MODULE_SPEC.md`, `PRODUCT_UI_BLUEPRINT.md`, and `DEVELOPMENT_PROGRESS.md` are the core context set for future implementation.

Verification:

- `git diff --check` passed on 2026-05-14 with line-ending warnings only.
- Verified framework headings and module numbering in `APP_FRAMEWORK.md` and `FUNCTION_MODULE_SPEC.md`.
- No ArkTS build was run for this phase because it changed documentation only.

## Phase 19: Future Schedule Ownership

Status: Done

Files changed:

- `flow/src/main/ets/pages/UpcomingPage.ets`
- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/resources/base/profile/main_pages.json`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a `未来` tab to the root navigation.
- Added `UpcomingPage` as the first Future surface.
- Future schedules are grouped into `明天`, `本周稍后`, and `以后`.
- Future items show date, weekday, start/end time, duration, and priority.
- Users can move a future schedule into Today; the schedule is assigned to the next practical Today time slot and records a schedule change.
- Users can send a future schedule back to Inbox by deleting that schedule while preserving the task and archiving the removed schedule.
- Updated the user guide and framework docs so Inbox, Today, Future, and Review responsibilities are clearer.

Verification:

- Initial build caught that `UpcomingPage` was registered in `main_pages.json` without `@Entry`; fixed by adding the required page entry decorator.
- `git diff --check` passed on 2026-05-14 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 20: Future Schedule Editing

Status: Done

Files changed:

- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added an edit action to each Future schedule item.
- Added a Future schedule editor sheet with title, duration, native `DatePicker`, native `TimePicker`, change note, delete, and save actions.
- Saving a Future edit preserves the existing schedule id and task link while updating scheduled date/time, end time, duration, title, and change history.
- Deleting from the editor archives the removed schedule before deleting it.
- Kept Future movement actions (`移到今天`, `退回收集箱`) alongside direct editing, so future work now has ownership and editability.
- Updated framework, function spec, and user guide to reflect Future editing.

Verification:

- `git diff --check` passed on 2026-05-14 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 21: Selectable Auto-Plan

Status: Done

Files changed:

- `flow/src/main/ets/pages/PlanPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Auto-plan suggestions now default to selected but can be individually deselected before applying.
- Each suggestion has an explicit `排除` action for the current planning pass; excluded tasks are not deleted and can be restored.
- Excluding a suggestion refreshes the plan from remaining Inbox tasks, so the user can curate the day instead of accepting a black-box batch.
- The auto-plan panel now shows selected count, selected minutes, remaining capacity after selected items, and temporarily skipped work.
- Plan primary actions now apply only selected suggestions; when nothing is selected, the action selects all suggestions instead of silently doing nothing.
- Updated product framework, module spec, UI blueprint, and user guide so selectable planning is part of the canonical product behavior.

Verification:

- `git diff --check` passed on 2026-05-14 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 22: Refinable Auto-Plan Suggestions

Status: Done

Files changed:

- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/utils/AutoPlanner.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Auto-plan suggestions now have compact up/down controls, so the user can move a suggested task earlier or later before applying it.
- Auto-plan suggestions now have `-10` and `+10` duration controls with 15-180 minute bounds.
- `AutoPlanner` now exposes a reflow helper that recalculates suggestion time windows after order or duration changes while respecting existing Today blocks.
- Plan shows feedback when a requested adjustment cannot fit into the current free windows.
- The Plan decision copy now reflects that generated suggestions are editable before they become real schedule blocks.
- Updated the product framework, module specification, UI blueprint, and user guide so reorder/refine behavior is canonical.

Verification:

- Initial build caught an unsupported ArkUI `TextAttribute.minWidth` usage; replaced it with fixed `width`.
- Second build caught function-typed `@Builder` parameters being emitted into invalid generated TS; replaced callback-style micro controls with explicit move/duration Builders.
- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 23: Plan Handoff To Focus

Status: Done

Files changed:

- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Applying a single Inbox task or selected auto-plan suggestions now moves Plan into the final `开始` step instead of leaving the user in the middle of the ritual.
- Plan now records the first newly created schedule block and shows a dedicated handoff panel after planning.
- The handoff panel shows the first block title, time window, duration, and priority.
- The user can now either start the first block directly from Plan or return to Today to inspect the full timeline.
- Starting from Plan opens the linked Focus page with schedule/task params and `autoStart`.
- Focus now accepts an `autoStart` route parameter and starts the timer after loading linked schedule context.
- Product framework, module spec, UI blueprint, and user guide now treat first-block handoff as part of the canonical Plan flow.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 24: Inbox Task Detail Depth

Status: Done

Files changed:

- `flow/src/main/ets/pages/InboxPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Inbox `整理` now acts as the first active Task Detail flow instead of only a scheduling form.
- The detail flow now loads and stores task subtasks through `TaskStep`.
- Users can add subtasks, toggle completion, and delete subtasks before scheduling the task.
- Inbox cards now show subtask progress metadata when a task has steps.
- `仅保存` persists title, priority, note, and subtask state without scheduling.
- `安排到时间线` preserves the edited task depth before creating the schedule block.
- Updated the app framework, module specification, product blueprint, and user guide to mark Inbox task depth as active.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 25: Scheduled Task Depth In Today And Future

Status: Done

Files changed:

- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Today timeline blocks now read the linked task note and subtask list after the task leaves Inbox.
- Today timeline blocks show note context and compact subtask chips when the linked task has depth.
- Today subtask chips can toggle completion directly without opening the schedule editor.
- Today editing is now an explicit `编辑` action inside the block, reducing accidental editor opens while checking subtasks.
- Future schedule items now read the linked task note and subtask list.
- Future items show note context, subtask progress, and compact subtask chips.
- Future subtask chips can toggle completion directly while keeping the schedule item in its grouped Future context.
- Product framework, module specification, UI blueprint, and user guide now treat scheduled task depth as part of the canonical behavior.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 26: Scheduled Task Editing From Today And Future

Status: Done

Files changed:

- `flow/src/main/ets/utils/TaskDepthUtils.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added `TaskDepthUtils` to centralize task step cloning, summary, add, toggle, delete, and task-depth update construction.
- Today schedule editor now loads the linked task's note, priority, and subtasks.
- Today schedule editor can edit task note, priority, add/delete/toggle subtasks, and save those changes back to the linked task.
- Today schedule editor keeps schedule title/time/duration controls together with task-depth fields in a scrollable sheet.
- Future schedule editor now loads and saves the linked task's note, priority, and subtasks.
- Future schedule editor can prepare a scheduled-later task with execution details before it reaches Today.
- Saving a Today/Future schedule edit now updates both the schedule row and linked task depth.
- Product framework, module specification, product blueprint, and user guide now mark scheduled task editing as active.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 27: Simple Scheduled Editing Disclosure

Status: Done

Files changed:

- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Self-check result: the scheduled edit sheet had become too form-heavy after adding task depth.
- Today schedule editor now keeps task note, priority, and subtask editing collapsed behind a `任务细节` section by default.
- Future schedule editor now uses the same progressive disclosure pattern.
- Each `任务细节` section shows a compact summary such as `有备注` or `子任务 1/3`, so users still understand what exists without seeing every field.
- Expanding `任务细节` preserves the previous full editing capability for note, priority, and subtasks.
- Updated product framework, module spec, UI blueprint, and user guide to make simplicity/progressive disclosure part of the canonical product behavior.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 28: Lightweight Routine Templates

Status: Done

Files changed:

- `flow/src/main/ets/models/DataModels.ets`
- `flow/src/main/ets/utils/RoutineEngine.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a lightweight `RoutineTemplate` model plus optional `routineId` linkage on tasks and schedules.
- Added `RoutineEngine` with three default templates: `晨间规划`, `深度工作`, and `收尾复盘`.
- Today now shows a compact `常用模板` strip when routine templates are still useful and the day is not already crowded.
- Tapping `加入` creates both the routine task and its schedule block for today.
- Each generated routine task includes a short note and small subtasks so the block has execution context.
- The same routine template is hidden after it is scheduled for today, preventing duplicate one-tap additions.
- Routine ids are preserved when Today/Future schedule edits or moves update existing routine schedules.
- Updated module spec, app framework, UI blueprint, and user guide to define this as the first simple routine version, not a full habit system.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 29: Master Feature Checklist

Status: Done

Files changed:

- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a single master feature checklist for the project with status markers: `Done`, `Active`, `Planned`, and `Docs/API Review`.
- Consolidated the current app roadmap across P0 core loop, P1 mature planning, and P2 system capabilities.
- Added a coverage table for the original `副本任务类功能.xlsx` requirements.
- Added a current product completion estimate of about 65% for a polished first usable release.
- Added the execution rule that future phases must map to checklist items and update the checklist after completion.
- Marked Review Insight Upgrade as the recommended next implementation phase because the core loop is now functional enough to need stronger interpretation.

Verification:

- Documentation-only phase. `git diff --check` passed on 2026-05-14 with line-ending warnings only.

## Phase 30: Review Insight Upgrade

Status: Done

Files changed:

- `flow/src/main/ets/utils/ReviewAnalyzer.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added `ReviewAnalyzer` to turn schedules, focus sessions, deleted archives, carry-over records, conflicts, and routine-generated blocks into concise daily insights.
- Review narrative now uses a structured report instead of only local page heuristics.
- Review now gives one practical recommendation for the next planning pass.
- Added a `计划质量` panel showing planned minutes, completed focus minutes, carry-over, routines, conflict state, and estimate accuracy.
- Added a `关键洞察` panel that explains overload, conflicts, carry-over pressure, routine usage, and frequent plan changes.
- Updated the master checklist: current first-release completion estimate moved from about 65% to about 72%.
- Marked Review insight explanation as done and set Focus Completion Polish as the next recommended phase.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 31: Focus Completion Polish

Status: Done

Files changed:

- `flow/src/main/ets/pages/FocusPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Focus completion now freezes the actual end time when the completion sheet opens, so reflection-writing time is not counted as focus time.
- Completion summary shows planned minutes, actual minutes, and estimate delta.
- Completion sheet previews the next unfinished block from today's remaining schedule when one exists.
- Completion actions are now clearer: return to Today, save completion, or start the next block directly.
- Starting the next block carries schedule/task context into Focus and can auto-start the timer.
- Focus completion navigation now handles `pushUrl` exceptions locally.
- Product docs now define completion handoff as part of the canonical Focus flow.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 32: Versioned Local Data Migration

Status: Done

Files changed:

- `flow/src/main/ets/utils/DataMigration.ets`
- `flow/src/main/ets/utils/DataManager.ets`
- `flow/src/main/ets/utils/Constants.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added `CURRENT_DATA_SCHEMA_VERSION` and a lightweight `DataMigration` utility.
- `DataManager.init()` now runs migration after Preferences initialization.
- Added `StorageKeys.DATA_SCHEMA_VERSION` to record the applied local data schema version.
- Migration normalizes older Preferences records for mood entries, tasks, schedules, schedule archives, focus sessions, rest sessions, user settings, and user info.
- Schedule migration supplies safe defaults for state, time window, reminders, history, actual minutes, and routine linkage.
- Task migration supplies safe defaults for color, priority, schedules, updated time, and task steps.
- Updated the master checklist estimate from about 72% to about 80%.
- Marked Focus completion and versioned data migration as done in the master checklist.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-14. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 33: Shared Task-Depth Data Contract

Status: Done

Files changed:

- `flow/src/main/ets/utils/TaskDepthUtils.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a shared `TaskDepthDraft` contract for scheduled task-detail editing.
- `TaskDepthUtils` now owns empty draft creation, task-to-draft creation, note extraction, step extraction, draft summary, depth hint text, step-title validation, and task-step toggling payloads.
- Today and Future schedule editors now initialize task-depth editing from the same helper instead of duplicating note/step setup.
- Today and Future inline subtask chips now use the same task-step toggle helper.
- Scheduled task-depth saves now preserve `routineId` on the linked task, preventing routine-generated tasks from losing their template linkage after editing.
- Updated the master checklist estimate from about 80% to about 82%.
- Marked Shared Task-Depth UI as active rather than done: the data contract is shared, while some ArkUI builder layout remains deliberately page-local to keep state binding simple.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are existing router deprecation, `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 34: Router API Review And Navigation Cleanup

Status: Done

Files changed:

- `flow/src/main/ets/utils/NavigationManager.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/SettingsPage.ets`
- `flow/src/main/ets/pages/TaskPage.ets`
- `flow/src/main/ets/pages/HomePage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Reviewed the official HarmonyOS application/API entry references and the local DevEco SDK declarations for `@ohos.router` and `UIContext.Router`.
- Added `NavigationManager` as the app route boundary using `UIContext.getRouter()`.
- Added explicit `RouteParams` for Focus handoff fields so ArkTS route parameter object literals stay typed.
- Replaced direct global `router.pushUrl`, `router.back`, and `router.getState` usages in app pages with the centralized wrapper.
- Preserved the existing user-facing route behavior: Today -> Inbox, Today -> Plan, Today/Plan -> Focus, Focus -> Today or next Focus.
- Updated the master checklist estimate from about 82% to about 84%.
- Marked router modernization as complete and set Final Simplicity And Interaction Polish as the next recommended phase.

Verification:

- `git diff --check` passed on 2026-05-15 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Router deprecation warnings are gone; remaining warnings are `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 35: Final Simplicity And Interaction Polish

Status: Done

Files changed:

- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Standardized visible main-loop page labels and route buttons away from mixed English UI copy: `收集`, `规划`, `复盘`, `回到今天`, and `去今天调整`.
- Made empty-title actions feel less misleading in Inbox capture and triage: empty titles now show muted action labels such as `输入后收集`, `先填标题`, and `先填写标题`.
- Added a Review next-step panel with real actions back to Today or Plan, so review no longer ends in a passive report.
- Added Future empty-state actions to go directly to Collect or Plan when there are no scheduled-later items.
- Tightened tomorrow/Future copy so scheduled-later work consistently refers back to `今天` rather than `Today`.
- Updated the master checklist estimate from about 84% to about 85%.
- Set Device Test And Release Readiness as the next recommended phase.

Verification:

- `git diff --check` passed on 2026-05-15 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are `@Entry export struct` preview guidance, obfuscation, and signing configuration warnings.

## Phase 36: Route Entry And Preview Warning Cleanup

Status: Done

Files changed:

- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/pages/HomePage.ets`
- `flow/src/main/ets/pages/TaskPage.ets`
- `flow/src/main/ets/pages/RecordsPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Split routed page entries from exported reusable page components.
- Main tab pages now keep exported `@Component` structs for `Index.ets` imports, while each file has a non-exported `@Entry` wrapper for router/page registration.
- Legacy routed pages `HomePage`, `TaskPage`, and `RecordsPage` use the same wrapper pattern to avoid reintroducing preview warnings.
- Entry wrappers use a `Column` root, matching the ArkTS compiler requirement that `@Entry` build methods have one container root.
- Updated the master checklist estimate from about 85% to about 86%.
- Set Device Runtime QA Pass as the next recommended phase.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. The `@Entry export struct` preview warnings are gone; remaining warnings are obfuscation and signing configuration warnings.

## Phase 37: Device Runtime QA Pass

Status: Blocked

Files changed:

- `docs/DEVELOPMENT_PROGRESS.md`

Attempted:

- Located the latest built HAP at `flow/build/default/outputs/default/app/flow-default.hap`.
- Located `hdc.exe` at `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe`.
- Ran `hdc list targets -v`; result was `[Empty]`, so no HarmonyOS phone/emulator target was available.
- Launched DevEco Emulator, then checked `hdc list targets -v` again; it still returned `[Empty]`, and no persistent emulator target appeared.
- Verified all routes listed in `main_pages.json` have matching `.ets` page files.
- Static-walked the current main loop:
  - Inbox capture creates an unscheduled task.
  - Inbox Today/Tomorrow/custom scheduling creates a schedule and shows moved-to-timeline feedback.
  - Today next action routes to linked Focus when a next schedule exists.
  - Focus completion saves a session, marks the linked schedule complete, and returns to Today or starts the next block.
  - Review reads analyzer output and now offers real next-step actions to Today or Plan.

Blocking condition:

- Real runtime tapping cannot be completed until `hdc list targets` shows a connected HarmonyOS device or running emulator.

Next action:

- Start a HarmonyOS phone emulator in DevEco or connect a phone with debugging enabled, confirm `hdc list targets -v` is not empty, then install `flow-default.hap` and run the full tap-through.

## Phase 38: Legacy Surface Pruning

Status: Done

Files changed:

- `flow/src/main/resources/base/profile/main_pages.json`
- `flow/src/main/ets/pages/HomePage.ets`
- `flow/src/main/ets/pages/TaskPage.ets`
- `flow/src/main/ets/pages/RecordsPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Removed obsolete migration-era pages from the active page profile: `HomePage`, `TaskPage`, and `RecordsPage`.
- Deleted the old page files so users cannot accidentally reach earlier, less polished surfaces through stale routes.
- Kept the shipped app surface focused on the Today-first operating loop: Today, Inbox, Plan, Future, Review, Focus, and Settings.
- Updated product/module docs so Task Detail is defined through Inbox detail flow and Today/Future schedule editors rather than the legacy `TaskPage`.
- Updated the master checklist estimate from about 86% to about 87%.

Verification:

- `git diff --check` passed on 2026-05-15 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 39: Review Range Switch

Status: Done

Files changed:

- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/utils/ReviewAnalyzer.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a `今天 / 本周` segmented switch to Review so the page can explain either a single day or the current week.
- Reworked Review data loading to filter focus sessions, mood entries, schedule changes, deleted-block archives, completion counts, and estimate drift by the active range.
- Extended `ReviewAnalyzer` with `buildReportForRange(...)`, so insight copy, capacity checks, carry-over signals, routine signals, and recommendations are generated from the selected range instead of being hard-wired to today.
- Updated change-feed timestamps to show date and time in the weekly view.
- Updated the master checklist estimate from about 87% to about 88%.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 40: Weekly Rhythm Review

Status: Done

Files changed:

- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/utils/ReviewAnalyzer.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added `ReviewDayStat` and weekly day-stat generation in `ReviewAnalyzer`.
- Added a compact `本周节奏` panel that appears in the Review weekly scope.
- The panel shows seven day rows with planned minutes, focus minutes, completion count, and whether that day had plan changes.
- Added a short rhythm hint that calls out overload, overly concentrated work, stable execution, or missing execution samples.
- Kept the chart intentionally small and text-light so Review stays useful rather than turning into a dense analytics dashboard.
- Updated the master checklist estimate from about 88% to about 89%.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 41: Today Next Action Clarity

Status: Done

Files changed:

- `flow/src/main/ets/pages/TodayPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Replaced the Today next-action inline ternaries with explicit state helpers for label, title, subtitle, accent color, button text, and route.
- Fixed the confusing empty-day state where the button could say `计划` while routing to Inbox.
- The next-action card now distinguishes four states:
  - Start the next active time block.
  - Review today when the timeline has no later active block.
  - Arrange existing Inbox items when today has no timeline.
  - Collect the first task when both today and Inbox are empty.
- Updated the master checklist estimate from about 89% to about 90%.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 42: Honest Capability Settings

Status: Done

Files changed:

- `flow/src/main/ets/pages/SettingsPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Renamed the Settings reminder section to `提醒偏好` so it no longer implies complete system reminder delivery.
- Added explanatory copy that notification, sound, and vibration settings are saved as preferences, while real system delivery still needs official capability review and device verification.
- Added an `应用能力` status card for core flow, local data, system reminder verification, and release signing.
- Updated the master checklist estimate from about 90% to about 91%.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 43: Settings Mainline Card

Status: Done

Files changed:

- `flow/src/main/ets/pages/SettingsPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a compact Settings `主线` card that shows the app loop as `收集 -> 安排 -> 专注 -> 复盘`.
- Kept it intentionally short and visual so Settings does not become a long instruction page.
- Added reusable small builders for the mainline nodes and connectors inside `SettingsPage`.
- Updated the master checklist estimate from about 91% to about 92%.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 44: Local Data Status Card

Status: Done

Files changed:

- `flow/src/main/ets/pages/SettingsPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a read-only Settings `本地数据` card.
- The card shows the current local schema version and counts for tasks, schedules, focus sessions, and archived schedule records.
- Added `loadDataStatus()` to Settings so counts reflect current local Preferences-backed data.
- Kept data reset, import, and export out of this phase because they need explicit safety and permission review.
- Updated the master checklist estimate from about 92% to about 93%.

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 45: Review Empty State Guidance

Status: Done

Files changed:

- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a Review empty-state guide for the first-run or no-data case.
- The guide explains that Review needs at least one arranged or executed time block before it can produce real insight.
- Added direct actions from empty Review to Inbox collection and Plan.
- Hid the dense analytics stack when there is no reviewable data, so users no longer see a page full of zero-value metrics and empty feeds.
- Updated the master checklist estimate from about 93% to about 94%.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-15. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 46: Plan Source Awareness

Status: Done

Files changed:

- `flow/src/main/ets/pages/PlanPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a Plan `可安排来源` panel so the planning flow shows both Inbox tasks and scheduled-later work before generating or applying a plan.
- The panel shows Inbox count, future schedule count, and today's already planned minutes.
- Future schedule rows show original date/time, duration, and priority, with a direct `移到今天` action.
- Moving a future schedule from Plan updates the existing schedule instead of creating a duplicate task, preserves schedule history, and moves the user to the ready-to-start handoff step.
- Updated the master checklist estimate from about 94% to about 95%.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-16. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 47: Runtime QA Readiness Polish

Status: Done

Files changed:

- `flow/src/main/ets/pages/Index.ets`
- `docs/DEVICE_QA_CHECKLIST.md`
- `docs/USER_GUIDE.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Made the bottom navigation clearer by changing the Review tab glyph from the same clock icon used by Future to a distinct cycle/review icon.
- Updated the user guide for the current Plan source flow, including `可安排来源` and `移到今天` behavior.
- Added `docs/DEVICE_QA_CHECKLIST.md` with the full device/emulator runtime walkthrough: Today, Inbox, Plan, Today timeline, Focus, Future, Review, Settings, and small-screen checks.
- Recorded the current runtime QA blocker: `hdc` exists in DevEco SDK, but `hdc list targets -v` currently returns empty, so no HarmonyOS target is available in this workspace.
- Updated the master checklist estimate from about 95% to about 96%.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `hdc list targets -v` was checked through the DevEco SDK hdc path on 2026-05-16 and returned empty, so device runtime QA remains blocked.

## Phase 48: Settings Experience Status

Status: Done

Files changed:

- `flow/src/main/ets/pages/SettingsPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/USER_GUIDE.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a Settings `体验状态` card that clearly separates static build status, device QA status, system reminder status, and release signing status.
- Kept the wording honest: the main flow is suitable for experience testing, but true release readiness still depends on device tapping, signing, and official system capability verification.
- Updated the About card from formal `版本 1.0.0` wording to `体验版 0.9.7` to avoid implying final release.
- Updated the user guide so Settings is documented as the place to check current experience status.
- Updated the master checklist estimate from about 96% to about 97%.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-16. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 49: Plan Future Fallback

Status: Done

Files changed:

- `flow/src/main/ets/pages/PlanPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/USER_GUIDE.md`
- `docs/DEVICE_QA_CHECKLIST.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Refined Plan's empty-Inbox behavior when scheduled-later work exists.
- The Plan primary action now offers to move a future item into Today instead of sending the user back to an empty Inbox.
- The auto-plan status, hint, action label, and decision-panel copy now explain that auto-plan handles Inbox tasks, while future work can be pulled into Today.
- Moving a future item still updates the existing schedule and preserves change history through the same Plan source flow.
- Updated the master checklist estimate from about 97% to about 98%.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-16. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 50: Startup Readiness Guard

Status: Done

Files changed:

- `flow/src/main/ets/pages/Index.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/DEVICE_QA_CHECKLIST.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a root startup readiness state in `Index.ets`.
- The app now shows a calm `正在准备本地数据` loading state while `DataManager.init()` and theme initialization run.
- Main tabs are mounted only after local Preferences and theme initialization complete, reducing the risk that child pages read empty local data on first launch.
- Updated the device QA checklist to verify that the startup loading state disappears quickly and the app opens on Today.
- Updated the master checklist estimate from about 98% to about 99%.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `hvigor assembleApp --no-daemon` passed on 2026-05-16. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 51: Static Release Handoff

Status: Done

Files changed:

- `docs/RELEASE_HANDOFF.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/DEVICE_QA_CHECKLIST.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added `docs/RELEASE_HANDOFF.md` as the final static handoff document for the current first-experience scope.
- Recorded the build command, latest known HAP path, HDC device-check command, install command, build warnings, current blocker, ready features, unclaimed features, and final release acceptance boundary.
- Linked the release handoff from the master checklist, app framework, and device QA checklist.
- Rechecked `hdc list targets -v`; it still returned empty output, so runtime QA remains blocked until a HarmonyOS phone or emulator target is available.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `git diff --check` passed on 2026-05-16 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-16. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 52: User Manual And PR Handoff

Status: Done

Files changed:

- `docs/USER_MANUAL.md`
- `docs/USER_GUIDE.md`
- `docs/RELEASE_HANDOFF.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added a formal user manual for the current Flow State experience scope.
- Documented the user mental model, page responsibilities, common workflows, task state movement, local data behavior, current limitations, and recommended use.
- Kept `docs/USER_GUIDE.md` as the quick-start guide and linked it to the formal manual.
- Updated release handoff and the master checklist so user-facing documentation is part of the PR scope.
- Preserved the current product boundary: static buildable app, with device QA, signing, and real system reminders still pending.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `git diff --check` passed on 2026-05-16 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-16. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 53: Route Stack And Theme Polish

Status: Done

Files changed:

- `flow/src/main/ets/utils/NavigationManager.ets`
- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `flow/src/main/ets/pages/SettingsPage.ets`
- `flow/src/main/ets/utils/AutoPlanner.ets`
- `flow/src/main/ets/utils/Constants.ets`
- `flow/src/main/ets/utils/ReviewAnalyzer.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Reduced route-stack growth in the main loop: tab-to-tab actions now switch the root Tabs instead of pushing routed tab pages.
- Focus completion now sets Today as the active root tab and backs out of Focus; starting the next Focus block uses `replaceUrl` so the Focus page does not stack repeatedly.
- Replaced the Today settings entry icon from the barrage/settings symbol to a gear symbol.
- Made theme selection visibly affect root tab colors, Today background/header controls, and Settings surfaces.
- Added an in-UI explanation for auto-plan logic: P0 -> P1 -> P2 priority, then creation order, while respecting existing blocks, capacity, and available gaps.
- Rebalanced harsh red/orange accents into low-saturation slate colors so alerts stay visible without breaking the cool blue/green visual direction.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 54: Theme Token And Focus Atmosphere Upgrade

Status: Done

Files changed:

- `flow/src/main/ets/utils/ThemeTokens.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/resources/base/media/focus_nature.png`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Added shared theme tokens for canvas, surface, subtle fills, selected fills, hairlines, muted text, accent colors, and primary foreground colors.
- Extended theme-linked rendering across Today, Inbox, Plan, Future, and Review so switching themes changes real page surfaces instead of only isolated controls.
- Rebuilt the Focus page visual layer around a local natural landscape resource, translucent overlays, glass-like cards, softer action controls, cleaner back affordance, and higher-contrast timer typography.
- Kept the Focus completion route-stack fix from Phase 53: completing a block returns to the root Today tab, while starting the next block uses replace navigation.
- Preserved the simple daily-loop interaction model while raising visual texture: natural atmosphere on Focus, calm blue/green/slate theme tokens elsewhere, and fewer harsh warning accents.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 55: Card Aesthetic And ArkUI Alpha Fix

Status: Done

Files changed:

- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/utils/ThemeTokens.ets`
- `flow/src/main/ets/components/common/GlassCard.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Fixed the bright yellow Focus rendering caused by CSS-style trailing-alpha colors. ArkUI color strings in this pass now use leading alpha for translucent colors.
- Replaced the malformed text-based Focus back affordance with a supported HarmonyOS symbol glyph.
- Retuned the Focus glass layers, timer ring, secondary controls, and rhythm strip so the natural background stays calm instead of becoming a saturated flat color.
- Upgraded the main-page card language toward a Structured/TickTick-style elevated surface: off-white card fill, hairline border, softer shadow, and more deliberate separation from the canvas.
- Updated `GlassCard` defaults so future shared cards inherit the same quieter visual system.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Reference product context:

- Structured App Store page: https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946
- TickTick App Store page: https://apps.apple.com/app/tick-tick/id626144601

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 56: Focus Safety Area And Material Card Polish

Status: Done

Files changed:

- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Made the Focus timer ring visually heavier by layering the ring background and active progress ring.
- Reduced the Focus primary pause/start button size and moved the lower completion controls upward to avoid the bottom home indicator area.
- Forced the Today header subtitle into one line with ellipsis so it no longer wraps into two lines beside the settings button.
- Restyled the Today next-action / review prompt from a flat purple action into a calmer elevated card with a muted left rail and tonal button.
- Added subtle metric tiles inside Today workload and Review metrics so the cards feel more deliberate without adding workflow complexity.
- Changed Review plan-quality carry-over and routine metrics to compact values so the right-side metrics no longer wrap into two lines.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Design reference context:

- Material Design foundations: https://m3.material.io/foundations
- Structured App Store page: https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946
- TickTick App Store page: https://apps.apple.com/app/tick-tick/id626144601

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 57: Planning Sheet Form Polish

Status: Done

Files changed:

- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Changed the Focus primary pause/start control from a square-like button to a wider rounded rectangle, matching the preferred Focus process button language.
- Reworked the Inbox "整理任务" sheet priority controls so the priority section is centered and uses balanced pill chips.
- Restyled task title, note, subtask empty states, and subtask rows in the triage and schedule editor sheets with quieter typography, soft filled surfaces, hairline borders, and more deliberate spacing.
- Replaced the separated date and end-time pickers with a unified "安排时间" card that shows the selected date/time summary and explains that the start point is inferred from duration.
- Restyled the Today schedule editor actions: "标记完成" is now a soft tonal button instead of a blunt green block; quick time actions and the save button now follow the same rounded, calm button system as the Focus flow.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 58: Modal Sheet Tab Bar Ownership

Status: Done

Files changed:

- `flow/src/main/ets/utils/NavigationManager.ets`
- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`

Implemented:

- Added a shared `flowTabBarCovered` AppStorage flag in `NavigationManager` so child tab pages can tell the root `Tabs` shell when a detail sheet needs full-screen ownership.
- Root `Index.ets` now collapses the bottom tab bar while a modal editing sheet is open, then restores it on tab change or page re-entry.
- Today schedule editing, Inbox triage, and Future schedule editing now hide the root tab bar when their detail sheets open and restore it when the sheet closes.
- This fixes the visual hierarchy issue where the bottom navigation appeared above the "adjust time block" detail sheet.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 59: Layered Paper Card System

Status: Done

Files changed:

- `flow/src/main/ets/utils/ThemeTokens.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`

Implemented:

- Added a Layered Paper token set: paper surfaces, inset paper, soft paper wash, paper border, thin shadow, heavier paper shadow, and calm teal/slate/green/lavender washes.
- Refined Today as the first card-system sample: workload, next action, timeline, free-space rows, schedule blocks, inbox strip, tomorrow preview, and routine/start/conflict/replan cards now use stronger material hierarchy instead of identical flat cards.
- Refined Review as the second sample: range chips, narrative recommendation, stats, planning quality, weekly rhythm, insights, and change feed now use paper cards, inset metric tiles, subtle separators, and quieter low-saturation status color.
- Improved timeline block states without changing scheduling logic: ongoing, completed, conflict, and missed blocks now get different soft surfaces while keeping the same task actions.
- Preserved the simple product flow: no new screens, no new required decisions, only visual hierarchy and card affordance upgrades.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Design reference context:

- Material Design foundations: https://m3.material.io/foundations
- Structured App Store page: https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946
- TickTick App Store page: https://apps.apple.com/app/tick-tick/id626144601

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 60: Dark Theme Contrast And Branding Direction

Status: Done

Files changed:

- `flow/src/main/ets/utils/Constants.ets`
- `flow/src/main/ets/utils/ThemeTokens.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`

Implemented:

- Softened the preset dark theme from near-black to a calmer deep blue-gray background.
- Raised dark-theme primary text contrast from pale gray to near-white so main content remains readable.
- Rebalanced dark card, paper, inset, border, wash, muted, secondary, and selected-surface tokens so night mode looks softer instead of overly black.
- Replaced remaining hardcoded black text in the Focus completion flow with theme text tokens.
- Replaced light-only Focus completion dialog surfaces with dark-aware card, mist, selected-surface, border, and muted text tokens.
- Replaced several light-only slate action backgrounds in Inbox, Plan, Today, and Future with dark-aware slate wash tokens.
- Kept the app-name/icon change as a branding decision: candidate names and icon-generation prompt are ready for user selection before resource replacement.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 61: Liuxu Branding And User-Facing Copy

Status: Done

Files changed:

- `flow/src/main/resources/base/element/string.json`
- `flow/src/main/module.json5`
- `flow/src/main/resources/base/media/startIcon.png`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/SettingsPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `flow/src/main/ets/utils/AutoPlanner.ets`
- `docs/DEVELOPMENT_PROGRESS.md`
- `docs/PRODUCT_UI_BLUEPRINT.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`

Implemented:

- Renamed the product from Flow State to `流序` in app strings, root surface text, Settings About, and Focus fallback title.
- Replaced the application icon resource with the user-provided glass document icon and pointed the module icon to the same single PNG resource.
- Fixed remaining dark-theme contrast gaps in Settings numeric inputs and capture/edit text inputs by applying theme-aware text and placeholder colors.
- Replaced selected-chip and primary-button text colors that used card-surface colors with white text so dark mode remains readable.
- Removed user-visible `P0 / P1 / P2` wording from plan explanations, future schedule priority badges, and auto-plan reasons; user-facing labels now read as priority intent such as `优先`, `重要`, and `常规`.
- Shortened developer-facing copy in Settings reminders, Today next-action guidance, Plan auto-arrange explanation, and tomorrow carry-over explanation.
- Kept the underlying priority enum and scheduling logic unchanged; only the visible language and contrast were changed.

Official docs context:

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
- HarmonyOS design concept: https://developer.huawei.com/consumer/cn/design/concept/

Verification:

- `git diff --check` passed on 2026-05-17 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-17. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 62: Centered Page Headers And Motto Copy

Status: Done

Files changed:

- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Centered the main tab page headers for Today, Inbox, Plan, Future, and Review.
- Added a left placeholder in Today header so the title stays visually centered while preserving the Settings gear on the right.
- Replaced explanatory subtitles with shorter motto-style lines that match each page:
  - Today: `今日事，今日毕。`
  - Inbox: `念起即记，心才有余。`
  - Plan: `先定其序，再行其事。`
  - Future: `远事先安，近事从容。`
  - Review: `温故知新。`

Verification:

- `git diff --check` passed on 2026-05-18 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-18. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 63: Product Voice Polish And Icon Boundary

Status: Done

Files changed:

- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/pages/SettingsPage.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `flow/src/main/ets/utils/ReviewAnalyzer.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Polished user-facing helper copy across empty states, planning hints, review insights, detail sheets, and Settings cards.
- Replaced instructional or implementation-like wording with shorter product lines that feel calmer and more aphoristic.
- Kept action labels practical where clarity matters, while making explanatory text more official and refined.
- Replaced remaining user-visible raw priority text in Plan metadata with `优先 / 重要 / 常规` labels.
- Reviewed icon usage. Current page icons rely on ArkUI/system symbol glyphs; Dribbble user work was not copied because there is no explicit license or source authorization in the repo.

Verification:

- `git diff --check` passed on 2026-05-18 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-18. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 64: Navigation And Header Polish

Status: Done

Files changed:

- `flow/src/main/ets/pages/Index.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Refined the bottom tab bar with selected icon capsules, theme-aware inactive colors, subtle borders, and lighter shadows.
- Replaced the loading subtitle with a calmer product line: `万事入序，稍候即启。`
- Added a small centered header mark to the five main tabs so centered titles feel more intentional and less plain.
- Kept the navigation model unchanged; this phase is purely visual and interaction-affordance polish.

Verification:

- `git diff --check` passed on 2026-05-19 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-19. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 65: Card Material Refinement

Status: Done

Files changed:

- `flow/src/main/ets/utils/ThemeTokens.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Tuned the shared card material tokens that drive Today, Plan, Review, Inbox, and Future cards.
- Light mode cards now use cleaner white/paper surfaces, softer inset fills, lighter borders, and deeper but more diffused shadows.
- Dark mode cards now use a softer blue-gray material stack rather than flat dark panels, with brighter hairlines and clearer selected surfaces.
- Kept layout and flow unchanged; this phase only raises perceived card depth and polish across existing UI.

Verification:

- `git diff --check` passed on 2026-05-19 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-19. Remaining warnings are obfuscation and signing configuration warnings.

## Next Phase Candidates

1. Run device/emulator runtime QA across collect -> schedule -> focus -> complete -> review.
2. Continue the Phase 59 card-polish system across Inbox/Plan/Future detail sheets.
3. Extract shared task-depth ArkUI builder only if it stays simpler than the current local builders.
4. Expand routines only after the default template strip feels useful in real use.
5. Start Projects/Tags only after the core collect -> schedule -> focus loop remains easy.
6. Add reminder/system capability only after official API review and device verification.

## Phase 66: Figma Brand And Premium Card Sync

Status: Done

Files changed:

- `flow/src/main/ets/utils/ThemeTokens.ets`
- `flow/src/main/ets/components/common/GlassCard.ets`
- `flow/src/main/ets/pages/TodayPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/pages/PlanPage.ets`
- `flow/src/main/ets/pages/ReviewPage.ets`
- `flow/src/main/ets/pages/UpcomingPage.ets`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Created a Figma page named `04 ArkTS Sync` in the user's design file, mapping the new `流序` logo direction and UI material system to implementation tokens.
- Recommended the `Flow Orbit` logo direction: three ordered nodes for collect, plan, and focus, with an open flow ring representing an editable timeline.
- Added richer ArkTS material tokens for action surfaces, brand line, blue/lavender accents, paper shadows, and glass veil surfaces.
- Upgraded the shared `GlassCard` component so future cards inherit theme-aware paper material, accent marks, larger radius, and softer depth.
- Refined high-traffic cards on Today, Inbox, Plan, Review, and Future with larger radii, stronger but softer shadows, bordered chips, and more tactile action buttons.
- Kept the existing product flow intact; this phase is a visual-system upgrade rather than a logic rewrite.

Verification:

- `git diff --check` passed on 2026-05-19 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-19. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 67: Temporary Rounded App Icon

Status: Done

Files changed:

- `flow/src/main/resources/base/media/startIcon.png`
- `docs/DEVELOPMENT_PROGRESS.md`

Implemented:

- Replaced the app launcher/start window icon with the user's selected Flow Orbit icon.
- Cropped the source image to a centered 1:1 icon and exported a 1024x1024 PNG.
- Applied an app-style rounded rectangle alpha mask so the icon has transparent rounded corners without adding an extra border.

Verification:

- Generated icon check: `Size=1024x1024; cornerA=0; centerA=255`.
- `git diff --check` passed on 2026-05-19 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-19. Remaining warnings are obfuscation and signing configuration warnings.

## Phase 68: Launch-Ready Copy Cleanup

Status: Done

Files changed:

- `README.md`
- `DELIVERY.md`
- `IMPLEMENTATION.md`
- `docs/USER_GUIDE.md`
- `docs/USER_MANUAL.md`
- `docs/RELEASE_HANDOFF.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/DEVICE_QA_CHECKLIST.md`
- `docs/APP_FRAMEWORK.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `flow/src/main/ets/pages/SettingsPage.ets`
- `flow/src/main/ets/pages/FocusPage.ets`
- `flow/src/main/ets/pages/InboxPage.ets`
- `flow/src/main/ets/utils/LiveWindowManager.ets`
- `flow/src/main/ets/flowability/FlowAbility.ets`
- `flow/src/main/ets/flowbackupability/FlowBackupAbility.ets`
- `flow/src/ohosTest/ets/test/Ability.test.ets`

Implemented:

- Rewrote public-facing README, user guide, user manual, delivery summary, and release handoff around the `流序 1.0` product story.
- Removed app-visible experience-version, device-waiting, pre-release, internal status, and test-tag wording.
- Replaced Settings app-status copy with product-facing language for core flow, local data, reminder preferences, and theme appearance.
- Simplified LiveWindowManager comments/log framing so it describes current in-app focus state instead of unfinished system capability work.
- Updated the master feature checklist to make launch-ready UI/copy polish the next recommended direction.

Verification:

- Source search found no app-visible `真机`, `体验版`, `待接入`, `发布前`, `QA`, `testTag`, `TODO`, or similar launch-inappropriate wording under `flow/src/main`.
- `git diff --check` passed on 2026-05-19 with line-ending warnings only.
- `hvigor assembleApp --no-daemon` passed on 2026-05-19.
