# Flow State App Framework

Updated: 2026-05-15

This document is the concrete execution framework for the app. `FUNCTION_MODULE_SPEC.md` defines detailed module requirements; `MASTER_FEATURE_CHECKLIST.md` is the source of truth for implementation status and what should be checked off next.

## 1. Product Spine

Flow State should be a HarmonyOS timeline-first planner, not a task-list app with a timer attached.

The core loop is:

1. Capture: put loose thoughts into Inbox quickly.
2. Clarify: decide whether an item belongs today, tomorrow, later, or a project.
3. Plan: turn selected work into a realistic timeline.
4. Focus: execute one block at a time.
5. Review: learn from completion, delay, overload, and estimate drift.

The app is successful when a user can open it and answer within 5 seconds:

- What should I do now?
- What is next?
- Is today realistic?
- Where did my captured tasks go?

## 2. Primary Information Architecture

### Main Tabs

| Tab | User Question | Role | Current Direction |
| --- | --- | --- | --- |
| 今天 | What should I do now? | Primary command center | Always first tab and first mental entry |
| 收集 | What have I not processed yet? | Fast capture and triage | Only unscheduled tasks live here |
| 规划 | How should I shape the day? | Guided planning ritual | Batch plan from Inbox and resolve workload |
| 未来 | What is coming later? | Upcoming/week/month timeline | First grouped version active |
| 复盘 | What happened and what should improve? | Daily/weekly review | Turns execution data into insight |

Implementation note: the current build now uses the five-tab operating loop: `今天 / 收集 / 规划 / 未来 / 复盘`.

### Secondary Surfaces

| Surface | Entry Points | Purpose |
| --- | --- | --- |
| Task Detail Sheet | Inbox item, timeline block, future item | Edit task title, notes, priority, subtasks, project, tags, reminders, schedules |
| Schedule Editor Sheet | Today timeline block, Future item | Move, resize, delay, advance, complete, delete, conflict-check |
| Focus Page | Today next block, timeline block | Execute a block with timer, pause, complete, reflection, actual/plan summary, and next-block handoff |
| Settings | Today header | Defaults, capacity, product mainline, theme, reminder preferences, local data status, app capability status, experience/release status |

## 3. Page-Level Framework

### 今天

Purpose: the operating dashboard.

Must show, in this order:

1. Day identity: date, weekday, one-line product cue.
2. Workload: planned minutes, capacity, completed, focus time, Inbox count.
3. Next action: current or next block with one primary action.
4. Timeline: today blocks, now line, free space, missed items, conflicts.
5. Tomorrow preview: items scheduled for tomorrow.
6. Inbox strip: unscheduled items that still need action.

Rule: if a task is scheduled, it must be visible somewhere near the main flow. Today owns today's execution and tomorrow preview; Future owns scheduled-later work.

Rule: the Today next action must match its real destination: start the next block, review a finished day, arrange existing Inbox work, or collect the first task.

### 收集

Purpose: capture without forcing immediate organization.

Must support:

- One-line capture.
- Priority choice.
- Quick schedule today.
- Quick schedule tomorrow.
- Custom triage with date, time, duration, note.
- Clear feedback after scheduling.

Rule: Inbox contains only unscheduled tasks. When a task leaves Inbox, the UI must explain where it went.

### 规划

Purpose: make the day executable.

The planning ritual:

1. Review yesterday and missed items.
2. Choose work from Inbox / routines / upcoming.
3. Estimate workload against capacity.
4. Order the timeline.
5. Start the first block.

Rule: planning is not just adding tasks. It must tell users when the day is overloaded or conflicting.

### 未来

Purpose: remove ambiguity around tomorrow and later.

Required first version:

- Tomorrow section.
- This week section.
- Later section.
- Tap item to open schedule editor.
- Move item to Today.
- Move item back to Inbox.

Later version:

- Week calendar.
- Month overview.
- Deadline and recurring task views.

### 复盘

Purpose: explain what happened.

Must answer:

- How much did I focus?
- What did I complete?
- What was delayed, deleted, carried over, or missed?
- Did I over-plan?
- Which estimates were wrong?

Rule: Review starts with narrative interpretation, then charts.

## 4. Domain Model Framework

### Core Entities

| Entity | Meaning | Current/Future Fields |
| --- | --- | --- |
| Task | A piece of work independent of time | title, note, priority, subtasks, project, tags, createdAt |
| Schedule | A time block on a day | taskId, date, end time, duration, dueAt, state, changeHistory |
| FocusSession | Actual execution record | scheduleId, taskId, start/end, planned/actual duration, pause count, reflection |
| Project | Long-term container | name, color, active/archive state |
| Tag | Lightweight context | name, color |
| Routine | Repeatable time block template | title, repeat rule, duration, default time |
| ReminderRule | Notification intent | scheduleId/taskId, offset, enabled |
| ReviewMetric | Derived insight | completion, focus, drift, carry-over, overload |

### State Rules

- A Task can exist without a Schedule; then it appears in Inbox.
- A Task with at least one future/active Schedule no longer appears in Inbox.
- A Schedule is the visible timeline unit.
- Schedule state must be one of planned, completed, deferred, cancelled.
- Deleting a Schedule archives it for Review.
- Carry-over creates a new Schedule and keeps the original as deferred history.

## 5. Technical Architecture Framework

### Presentation Layer

ArkUI pages and sheets:

- `Index.ets`: root navigation.
- `TodayPage.ets`: command center and timeline.
- `InboxPage.ets`: capture and triage.
- `PlanPage.ets`: guided planning.
- `UpcomingPage.ets`: future grouped timeline.
- `ReviewPage.ets`: analytics and interpretation.
- `FocusPage.ets`: execution.
- `SettingsPage.ets`: defaults.

Routed pages use a non-exported `@Entry` wrapper around the exported page component when that page also needs to be imported by `Index.ets`. This keeps route registration available while avoiding DevEco component preview warnings for exported entry structs.

Legacy migration pages `HomePage`, `TaskPage`, and `RecordsPage` have been removed from the active page profile. The shipped app surface is now the Today-first five-tab loop plus Focus and Settings.

Target rule: large page files should gradually delegate repeated UI and logic into helpers/components.

### Domain Utility Layer

Current and target utilities:

- `DataManager`: local persistence facade.
- `ScheduleAnalyzer`: conflicts, active windows, schedule math.
- `AutoPlanner`: capacity-aware scheduling suggestions.
- `PickerDateTime`: DatePicker/TimePicker conversion.
- `ReviewAnalyzer`: planned next, for summary and estimate drift.
- `RoutineEngine`: planned next, for repeat generation.
- `TaskDepthUtils`: shared note, subtask, draft, and task-depth update contract.
- `DataMigration`: schema-versioned normalization for older Preferences records.
- `NavigationManager`: UIContext Router wrapper for page navigation and typed route params.
- `ReminderEngine`: planned next, after official notification API review.

### Persistence Layer

Current baseline:

- Preferences-based local JSON storage through `DataManager`.
- Schema version and v2 migration through `DataMigration`.

Near-term requirement:

- Keep optional fields safe and migration-friendly.
- Add a new migration step before adding Projects/Tags/Reminders fields that become required by UI.

Future option:

- Move larger structured data to RDB when data volume and query complexity justify it.

### HarmonyOS API Boundary

Use official HarmonyOS documentation or local SDK declaration files before adding or changing system capabilities.

Confirmed current development references:

- Official application guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- Official API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- Local DevEco SDK declarations for ArkUI controls when checking component signatures.
- Local DevEco SDK declarations confirmed that deprecated global router calls should be replaced by `UIContext.getRouter()`; current page jumps are routed through `NavigationManager`.

System features that require official review before shipping:

- Notifications/reminders.
- Calendar integration.
- Background focus/live status.
- Widgets.
- Data export/import permissions.

Current Settings rule: preference toggles may be saved before system integration, but the UI must clearly say when a capability is not real delivery yet.

## 6. UI Framework

Visual direction: Fresh Graphite Timeline.

### Layout

- Today and Future are timeline-first.
- Inbox is slip/list-first.
- Plan is wizard/decision-first.
- Review is narrative/insight-first.
- Settings is quiet list-first.

Settings should clarify the product loop with a compact visual sequence, not a long help page.
Settings may show local data counts and schema version, but destructive reset and import/export should stay behind explicit permission and safety review.
Settings should use product-facing status language: main flow, local data, reminder preferences, theme appearance, and app identity.

### Color

Use neutral base and semantic accents:

- Base canvas: `#F7F8F6`
- Surface: `#FFFFFF`
- Mist surface: `#F0F4F3`
- Text: `#182126`
- Muted text: `#62727A`
- Primary action: `#256D85`
- Focus teal: `#46AFA5`
- Calm green: `#7BAE7F`
- Attention amber: `#D59A45`
- Urgent coral: `#D96B5F`
- Context lavender: `#8A7CC3`

### Interaction Rules

- Every visible button must either work or be clearly disabled.
- Every destructive action needs an obvious result or archive path.
- Every scheduling action needs visible feedback.
- Empty states must say what to do next.
- No fake AI panels or decorative analytics.
- The user should not need a tutorial to understand the next step.

## 7. Implementation Roadmap

Execution rule: new implementation phases must map to an item in `docs/MASTER_FEATURE_CHECKLIST.md`. After a phase is completed, update both the checklist status and `docs/DEVELOPMENT_PROGRESS.md`.

### Stage 1: Navigation And Trust

Goal: users understand the app immediately.

Status: complete for the current 1.0 scope; keep future refinements tied to the checklist.

Done:

- Today/Inbox/Plan/Review root.
- Chinese tab labels.
- Distinguishable bottom-tab glyphs. Current status: active; Review no longer shares the same clock glyph as Future.
- Inbox scheduling feedback.
- Today empty guide.
- Today state-aware next action. Current status: active.
- Tomorrow preview.
- First Future tab with tomorrow / this week / later groups.
- UIContext Router wrapper for core page jumps, back navigation, and Focus route params.
- Startup readiness guard. Current status: active; root tabs mount only after local data and theme initialization complete.

Ongoing refinement:

- Continue simplifying empty states, feedback, and disabled actions.

### Stage 2: Future And Schedule Ownership

Goal: nothing scheduled later feels lost.

Deliverables:

- `UpcomingPage.ets`. Current status: first version active.
- Tomorrow/This Week/Later grouped schedules. Current status: first version active.
- Move future item to Today. Current status: active.
- Move future item back to Inbox by deleting or cancelling schedule with clear state. Current status: active for single-schedule tasks.
- Open existing schedule editor from future item. Current status: first version active.
- Surface linked notes/subtasks on future items. Current status: active as a lightweight preview.
- Toggle linked subtasks from future items. Current status: active.
- Edit linked task note, priority, and subtasks from future item editor. Current status: active.

### Stage 3: Unified Task Detail

Goal: one consistent place to edit task depth.

Deliverables:

- Shared task detail sheet. Current status: not extracted yet; shared data contract is active through `TaskDepthUtils`.
- Notes/subtasks/priority edit from Inbox, Today, Future. Current status: active in Inbox detail and in Today/Future schedule editors; Today/Future now share draft and update helpers.
- Progressive disclosure for scheduled task details. Current status: active in Today/Future editors.
- Schedule summary per task. Current status: active as Today/Future schedule metadata and subtask counts.
- Safer delete/archive behavior.

Simplicity check:

- The default visible edit path should be title, time, duration, and save.
- Optional task depth should be visible as a summary, then expanded only when the user asks for it.
- A new module is not acceptable if it makes the collect -> schedule -> focus loop harder to understand.

### Stage 4: Planning Quality

Goal: the app feels like a planning assistant, not a form.

Deliverables:

- Select/deselect auto-plan suggestions. Current status: active in Plan.
- Plan source panel for Inbox and future schedules. Current status: active; future schedules can be moved into Today from Plan while preserving schedule history.
- Empty-Inbox future handoff. Current status: active; when Inbox has no tasks but Future has planned work, Plan points the primary action at moving future work into Today.
- Manual include/exclude. Current status: active for the current planning pass.
- Workload capacity explanation. Current status: active in auto-plan panel.
- Reorder suggested blocks. Current status: active through compact up/down controls.
- Refine suggested duration. Current status: active through compact duration controls.
- First-block start handoff. Current status: active through Plan handoff panel and Focus auto-start.

### Stage 4.5: Focus Completion

Goal: finishing a block should make the next step obvious.

Deliverables:

- Completion summary with planned minutes, actual minutes, and estimate delta. Current status: active.
- Reflection captured after the actual focus duration is frozen. Current status: active.
- Next-block preview from today's remaining timeline. Current status: active.
- Direct handoff to the next block when one exists. Current status: active.

### Stage 5: Routines And Recurrence

Goal: repeated days become easy.

Deliverables:

- Routine templates. Current status: first default template strip active in Today.
- Repeat rules.
- Generate routine blocks. Current status: active for today's default templates.
- Routine completion state.

Simplicity check:

- Routines start as a compact Today helper, not a standalone habit system.
- Templates must reduce daily setup work; they should not add a second planning workflow.

### Stage 6: Review And Insights

Goal: users learn how they actually plan.

Deliverables:

- Daily narrative summary. Current status: active.
- Lightweight weekly range review. Current status: active through the `今天 / 本周` Review toggle.
- Weekly rhythm bars. Current status: active as a compact seven-day planned/focus/completion view.
- Estimate accuracy. Current status: active.
- Carry-over and delay feed. Current status: active.
- Conflict, routine, overload, and carry-over explanation. Current status: active through `ReviewAnalyzer`.
- Empty Review guide. Current status: active; no-data Review now points users to collect or plan instead of showing a dense zero-state report.
- Rich weekly trend charts. Later; keep out unless the compact rhythm view proves insufficient.
- Priority/project/tag distribution after those models exist.

### Stage 7: System Capabilities

Goal: keep HarmonyOS integration purposeful and light.

Current scope:

- Reminder preferences are saved in Settings.
- Focus status is tracked in app state while a session is active.
- Local data remains the source of truth.

Future extensions:

- Widgets.
- Data export/import.
- Calendar integration if it strengthens the planning loop.

### Stage 8: Data Stability

Goal: local data survives product evolution.

Deliverables:

- Preferences schema version. Current status: active.
- Migration from unversioned data to v2 normalized records. Current status: active.
- Future migrations added before Projects/Tags/Reminders require new fields.

## 8. Immediate Next Build Phase

Next implementation should focus on high-polish product refinement from `docs/MASTER_FEATURE_CHECKLIST.md`.

Why:

- The main loop is clear enough to use without a guide.
- Every new feature should reduce planning friction, not add a second workflow.
- The strongest product gains now come from wording, visual hierarchy, and faster task editing.

Minimum acceptance:

- Collect -> schedule -> focus -> complete -> review remains direct.
- Today, Inbox, Plan, Future, Focus, Review, and Settings keep consistent product language.
- Sheet controls, picker layout, and action buttons remain usable on small screens.
- `assembleApp --no-daemon` passes.
- User flows remain: Today -> Inbox, Today -> Plan, Today/Plan -> Focus, Focus -> Today/next Focus.

Release handoff state: `docs/RELEASE_HANDOFF.md`.
