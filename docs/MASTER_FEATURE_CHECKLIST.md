# Flow State Master Feature Checklist

Updated: 2026-05-16

This is the execution checklist for Flow State. Future work should be chosen from this file, then reflected back into `DEVELOPMENT_PROGRESS.md` after implementation.

Status legend:

- ✅ Done: implemented and build-verified.
- 🟡 Active: usable first version exists, but important completion work remains.
- ⬜ Planned: product-approved direction, not implemented yet.
- 🔒 Docs/API Review: should only ship after HarmonyOS official API review.

## Product Completion Estimate

Current estimated completion for a high-quality first usable app: **about 99%**.

This does not mean every ambitious feature is 99% done. It means the core collect -> schedule -> focus -> review loop is now usable, Focus completion is clearer, local data has a versioned migration path, repeated task-depth data logic has a shared contract, page navigation has been moved behind a UIContext Router boundary, app startup now waits for local data/theme initialization before mounting the main tabs, the main loop now has clearer next-step actions and empty-input states, bottom tabs are more distinguishable, Today has a state-aware next-action card, Plan can now see both Inbox and future schedule sources and can pull future work into today when Inbox is empty, Settings exposes the product mainline, local data status, and honest experience/release status without over-promising system reminders, routed pages no longer use exported `@Entry` components, obsolete Home/Task/Records migration pages are no longer shipped, Review now supports both today and this-week scopes with a lightweight weekly rhythm chart plus a cleaner empty-state guide, device QA now has a concrete checklist, and release handoff state is documented. Remaining work is mostly device testing, release signing, reminder/system capabilities, and secondary organization.

Estimated remaining work to reach a polished first release:

| Area | Remaining Weight | Why It Matters |
| --- | ---: | --- |
| Review follow-up polish | 0% | Daily and lightweight weekly insights are active; empty Review now leads users back into collect or plan. |
| Shared component cleanup | 2% | Task-depth data logic is shared; some ArkUI builder layout is still repeated. |
| Reminder/system capability review | 4% | Reminder preferences are honest in Settings; real reminders still need official HarmonyOS API work. |
| Projects/tags or light organization | 3% | Useful later, but should not complicate the daily loop now. |
| Device/runtime QA and signing | 3% | Static build is cleaner and the device QA checklist exists; device route stack, keyboard, picker, sheet height, and signing still need final verification. |
| Final visual/interaction polish | 0% | Main-loop copy and next actions are cleaner; device testing should drive any last adjustments. |

## P0: Core Daily Loop

| Module | Feature | Status | Evidence / Notes | Next Action |
| --- | --- | --- | --- | --- |
| Today | Main tab is the default command center | ✅ | `Index.ets` routes to the Today-first IA. | Keep Today as first mental entry. |
| Today | Workload band with planned minutes and daily capacity | ✅ | Uses Settings capacity and overload text. | Minor visual polish only. |
| Today | Next action block with Start / Collect / Arrange / Review route | ✅ | State-aware copy and actions handle next focus block, no-more-blocks review, unscheduled Inbox work, and first capture. | Device-test route stack behavior. |
| Today | Chronological timeline blocks | ✅ | `TodayPage.ets` groups today's schedules by time. | Add drag/reorder later. |
| Today | Now indicator and free-space rows | ✅ | Timeline shows current point and gaps. | Tune spacing after device testing. |
| Today | Inbox strip and tomorrow preview | ✅ | Helps explain why Inbox tasks disappear after scheduling. | Keep compact. |
| Today | Conflict banner for overlapping active blocks | ✅ | `ScheduleAnalyzer.getConflicts`. | Add richer explanation in Review. |
| Today | Missed block detection and carry-over | ✅ | Missed blocks can move to tomorrow while preserving history. | Review should explain carry-over. |
| Today | Schedule edit sheet with date/time/duration | ✅ | Uses DatePicker/TimePicker-style controls. | Keep common fields visible by default. |
| Today | Linked notes/subtasks on schedule blocks | ✅ | Scheduled task depth appears after Inbox scheduling. | Extract shared UI later. |
| Today | Lightweight routine templates | ✅ | `常用模板` strip adds today templates once. | Expand only if real use proves useful. |
| Inbox | One-line capture with priority | ✅ | `InboxPage.ets` saves unscheduled tasks. | Keep capture fast. |
| Inbox | Schedule to Today / Tomorrow | ✅ | Creates schedules and removes task from Inbox. | Keep feedback visible. |
| Inbox | Triage sheet with title/note/priority/subtasks/date/time/duration | ✅ | First active task-detail flow. | Simplify if user testing says it feels heavy. |
| Inbox | Delete Inbox task | ✅ | Existing task deletion path. | Add archive later if needed. |
| Plan | Guided five-step planning ritual | ✅ | Review / choose / estimate / order / start flow exists, with source awareness for Inbox and scheduled-later work. | Tighten copy only after device testing. |
| Plan | Planning source panel | ✅ | Plan shows Inbox count, future schedule count, today's planned minutes, can move a future schedule into today while preserving history, and now treats future work as the next step when Inbox is empty. | Device-test source actions. |
| Plan | Capacity-aware auto-plan suggestions | ✅ | `AutoPlanner` respects existing blocks and capacity. | Add routines as an auto-source later if it stays simple. |
| Plan | Select, exclude, reorder, and resize suggestions | ✅ | Suggestions are editable before applying. | Keep controls compact. |
| Plan | Handoff to Focus after planning | ✅ | First created block can auto-start Focus. | Keep the handoff obvious. |
| Future | Tomorrow / this week / later groups | ✅ | `UpcomingPage.ets` owns scheduled-later work. | Add calendar views later. |
| Future | Move future item to Today or back to Inbox | ✅ | Schedule update/delete flows active. | Preserve clear feedback. |
| Future | Edit future item and linked task depth | ✅ | Future editor mirrors Today simple disclosure. | Extract shared editor later. |
| Focus | Linked timer from schedule/task | ✅ | Focus accepts schedule/task params, can auto-start from Plan/Today, and previews the next block after completion. | Device-test auto-start and next-block handoff. |
| Focus | Save session and update schedule completion | ✅ | Completion freezes actual minutes, updates the linked schedule, and can return to Today or start the next block. | Device-test completion edge cases later. |
| Review | Basic narrative and real data metrics | ✅ | Review uses focus/change/archive data, explains plan quality, can switch between today and this week, shows a weekly rhythm chart, and presents a task-oriented guide when there is no reviewable data yet. | Device-test range switching and empty-state actions. |
| Navigation | UIContext Router boundary | ✅ | `NavigationManager` wraps `UIContext.getRouter()` and typed route params for page jumps/back navigation. | Device-test stack/back behavior. |
| Navigation | Startup readiness guard | ✅ | Root `Index` shows a local-data loading state until Preferences and theme initialization complete, then mounts the main tabs. | Device-test first launch timing. |
| Navigation | Distinguishable bottom tabs | ✅ | Review no longer shares the same clock glyph as Future. | Device-test symbol rendering. |
| Flow Polish | Main-loop next-step actions and disabled-looking empty states | ✅ | Today/Review have state-aware next actions; Review no longer shows a dense zero-state analytics stack; Future empty state routes to Collect/Plan; empty title buttons no longer look fully active. | Device-test with real thumb flow. |
| Release Readiness | Route entry/component split | ✅ | Exported page components are no longer decorated with `@Entry`; each routed page has a non-exported entry wrapper. | Device-test routed pages. |
| Release Readiness | Remove obsolete legacy pages | ✅ | `HomePage`, `TaskPage`, and `RecordsPage` are removed from active page profile/source; shipped surface is Today/Inbox/Plan/Future/Review plus Focus/Settings. | Device-test route profile. |
| Release Readiness | Honest system-capability status | ✅ | Settings explains reminder preferences, core flow, local data, system reminder verification, and signing status. | Replace status copy after real reminders/signing ship. |
| Release Readiness | Static handoff package | ✅ | `docs/RELEASE_HANDOFF.md` records build command, HAP path, device check, install command, and final acceptance boundary. | Use it once a device/emulator target is available. |
| Release Readiness | User manual and quick-start guide | ✅ | `docs/USER_MANUAL.md` explains the product mental model, pages, workflows, task states, current limits, and official HarmonyOS documentation context. | Use it for first experience testing and future onboarding copy. |
| Settings | Product mainline summary | ✅ | Settings shows the compact 收集 -> 安排 -> 专注 -> 复盘 loop without turning into a guide page. | Keep concise. |
| Settings | Local data status | ✅ | Settings shows schema version and local counts for tasks, schedules, focus sessions, and archives. | Add export/import only after permission review. |
| Settings | Experience/release status | ✅ | Settings shows build, device QA, system reminder, and signing readiness honestly, and the About card uses experience-version wording. | Replace copy after device QA/signing pass. |

## P1: Mature Planning

| Module | Feature | Status | Evidence / Notes | Next Action |
| --- | --- | --- | --- | --- |
| Task Detail | Shared task-depth UI component/surface | 🟡 | `TaskDepthUtils` now owns drafts, hints, summaries, toggles, and updated task payloads for Today/Future. | Extract shared ArkUI builder only if it stays simple. |
| Review | Explain conflicts, carry-over, routines, and estimate drift | ✅ | `ReviewAnalyzer` turns execution data into short readable insights and day-by-day week stats. | Keep charts minimal. |
| Data | Versioned data model and migrations | ✅ | `DataMigration` normalizes Preferences data and Settings exposes the current schema/count status. | Add future migrations before Projects/Tags/Reminders. |
| Routines | Default routine template strip | ✅ | Today can add three default templates. | Do not expand until tested. |
| Routines | Repeat rules / generated future blocks | ⬜ | Not implemented. | Keep out of P0. |
| Projects/Tags | Project and tag models | ⬜ | Spec exists only. | Add after core loop testing. |
| Projects/Tags | Filters and workload by project/tag | ⬜ | Spec exists only. | Depends on models. |
| Natural Input | Natural-language quick add | ⬜ | Planned. | Needs parsing boundary review. |
| Schedule | Drag/reorder timeline blocks | ⬜ | Planned. | Add only after current tap/edit UX is stable. |
| Future | Week/month calendar views | ⬜ | Planned. | Secondary to daily loop. |

## P2: System Capabilities

| Module | Feature | Status | Evidence / Notes | Next Action |
| --- | --- | --- | --- | --- |
| Reminder Engine | Store reminder preferences | ✅ | Settings stores notification/sound/vibration preferences without claiming real delivery. | Add full rule model only with real notification work. |
| Reminder Engine | Real HarmonyOS notification/alarm delivery | 🔒 | Requires official API review and device verification. | Do not fake. |
| Calendar | System calendar integration | 🔒 | Requires official API and permission review. | Later. |
| Background / Live status | Background focus/live state | 🔒 | Requires official API review. | Later. |
| Widget | Home screen widget | 🔒 | Requires official API review. | Later. |
| Export/Import | Data export/import | 🔒 | Requires storage/permission review. | Later. |

## XLSX Requirement Coverage

Source: `副本任务类功能.xlsx`

| XLSX Module | XLSX Feature | Current Coverage | Status | Notes |
| --- | --- | --- | --- | --- |
| 时间设置 | 精确时间 | Schedule date/time/dueAt and overdue/missed detection | ✅ | Today editor supports precise date/time. |
| 时间设置 | 区间时间 | Schedule duration creates start/end window | 🟡 | Time blocks have start/end; broader week/month range planning is later. |
| 提醒机制 | 闹钟提醒 | Not implemented | 🔒 | Needs real HarmonyOS notification/alarm API review. |
| 提醒机制 | 自定义提醒 | Not implemented | 🔒 | Needs reminder model plus official API review. |
| 任务操作 | 延后/提前 | Today schedule edit quick actions | ✅ | Change history records adjustments. |
| 任务操作 | 变更备注 | Schedule change note | ✅ | Delay/advance/edit can store notes. |
| 状态展示 | 进行中标识 | Today timeline status chips and ongoing state | ✅ | Active block status is visible. |
| 状态展示 | 优先级排序 | Inbox/Plan priority-aware sorting | 🟡 | Implemented in key lists; future global sorting can improve. |

## Current Recommendation

Next implementation should be **Device Runtime QA Pass** using `docs/DEVICE_QA_CHECKLIST.md` and `docs/RELEASE_HANDOFF.md`:

1. Run the app on device/emulator and walk the full loop: collect -> schedule -> focus -> complete -> review.
2. Fix any route-stack, keyboard, picker, sheet height, or small-screen spacing issues found in real interaction.
3. Prepare signing/release configuration only after the runtime loop is stable.

Reason: static build noise is now low enough to focus on actual runtime behavior. The next highest-value work is confirming the app on HarmonyOS device/emulator before adding larger organization or system-capability modules.
