# Flow State Full Function Module Specification

Updated: 2026-05-15

This is the authoritative module context for Flow State. Future implementation should use this document together with `APP_FRAMEWORK.md`, `PRODUCT_UI_BLUEPRINT.md`, `MASTER_FEATURE_CHECKLIST.md`, and `DEVELOPMENT_PROGRESS.md`.

## Product Definition

Flow State is a timeline-first daily planning app. It helps users capture scattered work, turn it into a realistic day plan, execute one focus block at a time, and review what happened.

The app is not a generic checklist. The primary mental model is:

1. Capture everything quickly.
2. Decide what matters today.
3. Arrange work into a realistic timeline.
4. Start the next block.
5. Review and improve the plan.

## Module Map

| Module | Role | Primary Screen | Status |
| --- | --- | --- | --- |
| Today | Main daily operating surface | `TodayPage` | Partial - execution state active |
| Inbox | Fast capture and triage | `InboxPage` | Partial - triage sheet active |
| Plan | Guided daily planning ritual | `PlanPage` | Partial - interactive ritual active |
| Future | Tomorrow, week, and later schedule ownership | `UpcomingPage` | Partial - grouped future list active |
| Task Detail | Deep task editing without cluttering lists | `InboxPage` detail flow, Today/Future schedule editors, scheduled block previews | Partial - task depth visible in Inbox/Today/Future |
| Focus | Execution surface for one time block | `FocusPage` | Active - completion and next-block flow active |
| Review | Reflection and analytics | `ReviewPage` | Partial - real change analytics active |
| Schedule Editing | Adjust time blocks | `TodayPage` bottom sheet | Partial |
| Navigation | Route boundary and page movement | `NavigationManager` | Active - UIContext Router wrapper in use |
| Reminder Engine | Real notifications/alarms | Future system module | Research |
| Projects/Tags | Long-term organization | Future library module | Planned |
| Routines/Habits | Repeating daily structures | Future routine module | Planned |
| Settings | Preferences and system configuration | `SettingsPage` | Active - preferences, local data, and readiness status visible |
| Data Layer | Local persistence and migration | `DataManager`, `DataMigration` | Active - schema version and v2 migration active |

## Global UI Language

Visual style: Fresh Graphite Timeline.

Color rules:

- Canvas: warm off-white `#F7F8F6`.
- Main surfaces: white.
- Secondary surfaces: mist `#F0F4F3`.
- Primary text: graphite `#182126`.
- Secondary text: muted slate `#62727A`.
- Action blue: `#256D85`.
- Focus teal: `#46AFA5`.
- Calm green: `#7BAE7F`.
- Attention amber: `#D59A45`.
- Urgent coral: `#D96B5F`.
- Context lavender: `#8A7CC3`.
- Slate: `#607385`.

Layout rules:

- Today is timeline-first, not card-first.
- Today is the primary entry surface and bottom navigation labels use clear Chinese user language.
- Use cards only for grouped controls, repeated items, and sheets.
- Avoid nested cards.
- Use small semantic accents, not full-screen color blocks.
- Mobile headers stay compact: 26-30sp.
- Metadata stays small: 10-12sp.
- Buttons must always perform an action or be visually disabled.

## Module 1: Today

### User Goal

The user opens the app and immediately understands what to do now, what comes next, and whether today is overloaded.

### Core Data

- Today schedules.
- Inbox task count.
- Completed focus sessions.
- Total planned minutes.
- Total actual focus minutes.
- Next schedule block.
- User daily capacity setting.

### Required Functions

- Show date, weekday, and planning load.
- Show planned minutes against the user-configured daily capacity.
- Warn when planned minutes exceed capacity.
- Show state-aware next action with Start / Review / Arrange / Collect action.
- Show vertical timeline blocks in chronological order.
- Show Inbox preview.
- Show tomorrow preview for items scheduled from Inbox to tomorrow.
- Show first-run guidance when the day has no timeline blocks.
- Start linked focus session when a next block exists.
- Navigate to Review when the day has timeline history but no later active block.
- Navigate to Inbox with accurate copy when the next step is capture or arranging unscheduled work.
- Show now indicator.
- Show free-space rows between blocks.
- Open schedule edit sheet from a timeline block.
- Edit title, date, time, and duration.
- Use native picker-style date and time inputs for manual schedule editing.
- Delay, advance, move to tomorrow, and delete a block.
- Mark a block completed from the edit sheet.
- Reflect Focus completion back into the linked schedule block.
- Show linked task notes and subtask progress inside timeline blocks when available.
- Allow lightweight subtask toggling from a scheduled Today block without opening a full editor.
- Edit linked task note, priority, and subtasks from the Today schedule editor.
- Keep linked task fields collapsed behind `任务细节` by default so the core edit path stays simple.
- Archive deleted blocks for Review.
- Detect missed blocks after their planned end time.
- Carry missed blocks over to tomorrow in one action.
- Keep the original block as deferred history after carry-over.
- Detect overlapping active time blocks.
- Show a conflict banner with the first overlap and a direct edit action.
- Later: drag/reorder.

### UI Description

Top:

- Large `Today` title.
- Date and weekday.
- Settings icon in a small white square.

Workload band:

- Planned minutes as the main number.
- Capacity text: remaining minutes or overloaded amount.
- Capacity comes from Settings, with 300 minutes as the default fallback.
- Thin progress bar.
- Four metrics: blocks, Inbox, completed, focus hours.

Next action:

- A left semantic color rail.
- State label, title, and short next-step explanation.
- Primary action button:
  - `开始` when a next block exists.
  - `复盘` when the day has a timeline but no later active block.
  - `安排` when Inbox has unscheduled work but today has no timeline.
  - `收集` when both today and Inbox are empty.

Timeline:

- Time rail on the left.
- Dot and vertical guide.
- Block content on the right.
- Duration and parent task shown as metadata.
- Linked note appears as a compact inset when the task has context.
- Up to two subtasks can appear as inline chips under the time block; checking them updates the task state.
- Now indicator uses a small coral line and timestamp.
- Gaps of 20+ minutes appear as schedulable free-space rows.
- Tapping a block opens the schedule edit sheet.
- Missed-block banner appears above the timeline when there are overdue unfinished blocks.
- Carry-over creates tomorrow blocks and keeps today's timeline accountable.
- Conflict banner appears above next action when active blocks overlap.
- Conflicting timeline blocks use a coral status chip and border.
- Empty state explains how to start.

Inbox strip:

- Shows first 3 unscheduled tasks.
- Tapping an item opens Inbox.

### Acceptance Criteria

- User can start the next focus block in one tap.
- If the day is empty, the primary action clearly leads to capture or arranging Inbox work.
- If the day has no later active block, the primary action clearly leads to Review.
- User can understand the collect -> schedule -> focus flow from the Today empty state.
- Every visible button works.
- Planned workload is visible without scrolling.
- Workload color and remaining-time copy follow the Settings daily capacity.
- Existing blocks can be changed without recreating the task.
- Completed blocks remain visible as completed timeline history.
- Scheduled task notes and subtask state remain visible from Today after the task leaves Inbox.
- Tapping a subtask chip updates the task without losing the user's place in Today.
- Editing a Today block can update both the schedule and its linked task depth.
- Missed blocks can be carried over without losing today's review history.
- Overlapping active blocks are visible before the user starts the day.

## Module 2: Inbox

### User Goal

Capture tasks without deciding where they belong yet, then quickly schedule or triage them.

### Core Data

- Unscheduled tasks.
- Task priority.
- Created time.
- Optional note and subtasks.

### Required Functions

- One-line capture.
- Priority selection during capture.
- List all unscheduled tasks.
- Schedule task to today.
- Schedule task to tomorrow.
- After scheduling, show clear feedback that the task moved into the timeline.
- Open triage sheet from an Inbox task.
- Edit title, note, priority, duration, date, and time.
- Add, complete, and delete subtasks from the Inbox detail flow.
- Schedule custom date/time.
- Delete an Inbox task.
- Later: natural-language parsing, archive, one-by-one triage mode.

### UI Description

Top:

- `Inbox` title.
- Short explanation of capture-first behavior.

Capture panel:

- Large input.
- Priority chips: P0/P1/P2 using coral/amber/slate.
- Capture button.

Inbox list:

- Each task has left priority rail.
- Title and status.
- Quick actions: Today, Tomorrow, Triage.
- Triage sheet uses calm bottom-sheet controls and date/time chips.
- Triage sheet uses native picker-style date and time inputs for custom scheduling.
- Triage sheet doubles as the first unified task detail surface, with notes and subtasks above scheduling controls.
- Scheduling feedback banner explains why an item leaves Inbox and provides a direct route back to Today.

### Acceptance Criteria

- User can capture a task in under 3 seconds.
- User can schedule an Inbox task into today or tomorrow.
- Scheduled tasks disappear from Inbox after reload.
- Scheduled tasks no longer disappear without explanation.
- User can turn an Inbox item into a custom timeline block.
- User can add context notes before scheduling.
- User can split an Inbox task into subtasks before scheduling it.

## Module 3: Plan

### User Goal

Plan the day through a guided ritual rather than manually maintaining a list.

### Core Data

- Inbox count.
- Today schedule count.
- Planned minutes.
- Total tasks.
- User daily capacity setting.
- Default focus duration setting.
- Yesterday unfinished tasks later.

### Required Functions

- Show workload before planning.
- Guide user through five planning steps:
  - Review.
  - Choose.
  - Estimate.
  - Order.
  - Start.
- Interactive stepper for the five planning steps.
- Each step has a real action target.
- Schedule the top Inbox task into today's timeline.
- Show a source panel for Inbox tasks and scheduled-later work.
- Move a future schedule into today from Plan without recreating the task.
- When Inbox is empty but future work exists, make the primary Plan action move a future item into today instead of dead-ending at Inbox.
- Show today timeline preview while planning.
- Show tomorrow carry-over blocks and minutes.
- Use the Settings daily capacity for near-limit and overloaded states.
- Use the Settings default focus duration when auto-scheduling a task.
- Detect today's overlapping active blocks before adding more work.
- Generate a capacity-aware auto-plan from Inbox tasks.
- Respect existing timeline blocks, daily capacity, priority order, and usable free windows.
- Apply multiple suggested blocks to Today in one action.
- Let the user select or deselect generated auto-plan suggestions before applying.
- Let the user exclude a suggestion from the current planning pass and refill the suggestion list from remaining Inbox tasks.
- Let the user move a generated suggestion earlier or later before applying.
- Let the user adjust generated suggestion duration in small increments before applying.
- Recompute generated suggestion time windows after order or duration changes.
- After applying a plan, show the first executable block and offer a direct start action.
- Let Plan hand off directly into Focus with the linked schedule already loaded.

### UI Description

Top:

- `Plan` title.
- Explanation: planning is making the day executable.

Workload panel:

- Planned minutes.
- Status chip: enough space / near limit / overloaded.
- The near-limit threshold is 70% of daily capacity.
- Metrics for today blocks, Inbox, total tasks.
- Conflict count appears beside workload metrics.
- Source panel shows Inbox count, future schedule count, and today's planned minutes.
- Future source rows show original date/time, duration, priority, and a direct `移到今天` action.
- Empty-Inbox planning copy should point to future work when future work exists.
- Auto-plan panel shows generated suggestions, remaining capacity after applying them, and skipped work.
- Auto-plan suggestions have a clear selected state, a direct exclude action, and a recovery area for excluded tasks.
- Auto-plan suggestions expose compact order and duration controls without opening another sheet.
- Adjustment feedback appears when the current free windows cannot fit a requested change.
- Plan handoff panel appears after applying suggestions, showing the first block title, time window, duration, and priority.

Planning steps:

- Numbered row.
- Accent circle by step.
- Step title and purpose.
- Active-step decision panel with primary and secondary actions.
- Conflict panel appears when today's time blocks overlap.
- Tomorrow carry-over panel when missed work has been moved forward.
- Today preview showing the first planned blocks.

### Acceptance Criteria

- No step looks clickable unless it does something.
- The user understands the planning sequence without tutorial text.
- Workload status is visible before selecting more tasks.
- A task can be moved from Inbox into today directly from Plan.
- A scheduled-later task can be moved into today directly from Plan while preserving schedule history.
- If Inbox is empty but future work exists, Plan still offers a useful next action.
- Tomorrow planning is aware of carried-over work before adding more tasks.
- Capacity warnings stay consistent with the Today workload band.
- Plan warns the user to resolve timeline conflicts before continuing.
- Plan can turn several Inbox tasks into realistic Today blocks without creating overlaps.
- Plan only applies the suggestions the user selected.
- Excluding a suggestion does not delete the task; it stays in Inbox and can be restored into the planning pass.
- Reordering or changing duration preserves non-overlapping planned windows.
- After planning, the user can start the first focus block without hunting for it in Today.

## Module 4: Future

### User Goal

The user can see everything that was scheduled beyond today, especially tasks sent to tomorrow from Inbox.

### Core Data

- Tomorrow schedules.
- This week schedules.
- Later schedules.
- Linked task metadata.
- Schedule state and priority.

### Required Functions

- Show tomorrow, this week, and later groups.
- Open scheduled item detail or schedule editor.
- Edit title, date, end time, duration, and change note from Future.
- Show linked task notes and subtask progress on future schedule items.
- Allow lightweight subtask toggling from Future schedule items.
- Edit linked task note, priority, and subtasks from the Future schedule editor.
- Keep linked task fields collapsed behind `任务细节` by default so the Future edit path stays simple.
- Move a future block to Today.
- Send a future block back to Inbox by cancelling/removing the schedule without deleting the task.
- Keep future work out of Inbox while still making it visible.
- Show visible feedback after moving a future block.
- Later: week/month calendar view.

### UI Description

- Quiet grouped list, not a dense calendar at first.
- Tomorrow group appears first.
- Each item shows date, time, title, duration, priority, and quick actions.
- Items can expose the linked task note and the first subtasks without becoming visually dense.
- Edit action opens a compact bottom sheet with native date/time pickers.
- Empty state explains that Inbox is for unscheduled work and Future is for scheduled-later work.

### Acceptance Criteria

- A task scheduled to tomorrow is visible outside Inbox.
- User can move a future task into Today.
- User can return a future task to Inbox.
- User can edit an existing future schedule without recreating it.
- User can confirm a scheduled-later task's notes/subtasks without sending it back to Inbox.
- User can edit a scheduled-later task's note, priority, and subtasks without sending it back to Inbox.
- No scheduled future task feels lost.

## Module 5: Task Detail

### User Goal

Keep lists clean while still allowing full task depth.

### Core Data

- Title.
- Priority.
- Note.
- Subtasks.
- Schedules.
- Reminder settings.
- Later: tags, project, recurrence, change history.

### Required Functions

- Open detail sheet from a task.
- Edit title.
- Edit priority.
- Edit note.
- Add/toggle/delete subtasks.
- Schedule task to a date/time/duration.
- Inbox detail flow stores title, priority, note, and subtasks on the task before scheduling.
- Scheduled Today/Future blocks surface notes and subtask progress from the linked task.
- Today/Future subtask chips can toggle completion state directly.
- Today/Future schedule editors can update linked task title, priority, note, and subtasks.
- Today/Future schedule editors expose task depth through progressive disclosure, not a full always-visible form.
- Shared task-depth helpers own note extraction, step summaries, draft initialization, step mutations, and updated task payloads.
- Later: extract a unified full editor component, reorder subtasks, assign project/tag, view history.

### UI Description

Sheet header:

- Task title context.
- Schedule/subtask summary.
- Done action.

Sections:

- Title input.
- Priority chips.
- Notes field.
- Subtasks list.
- Add subtask input.
- Schedule controls.

### Acceptance Criteria

- Task cards remain compact.
- Task detail stores meaningful data locally.
- Inbox task can become a scheduled block from detail.
- Subtask state persists after closing and reopening the Inbox detail flow.
- Subtask state remains usable after the task becomes a Today/Future schedule block.
- Scheduled task edits persist to the linked task, not only the visible schedule row.
- Editing scheduled task depth preserves routine linkage and uses the same helper contract in Today and Future.

## Module 6: Focus

### User Goal

Execute one time block with minimal distraction.

### Core Data

- Schedule id.
- Task id.
- Planned duration.
- Actual duration.
- Pause count.
- Completion state.
- Reflection.

### Required Functions

- Start timer from Today or schedule row.
- Pause/resume.
- Complete/cancel.
- Save focus session.
- Mark linked schedule as completed when a focus session is completed.
- Capture reflection.
- Store actual focus minutes on the linked schedule.
- Freeze actual duration when the completion sheet opens, so reflection time is not counted as focus time.
- Show planned duration, actual duration, and estimate delta after completion.
- Preview the next available block from today after completion.
- Let the user return to Today or start the next block directly.
- Later: rest timer and background/live status after official docs review.

### UI Description

- Dark immersive surface with graphite/teal palette.
- Linked task and schedule context at the top.
- Large ring timer with remaining/elapsed label.
- Primary circular Start/Pause/Continue control.
- Secondary Complete and Abandon actions.
- Rhythm strip for planned minutes, elapsed minutes, and pause count.
- Reflection sheet after completion with planned/actual/delta metrics and next-block preview.
- Primary completion action starts the next block when one exists; otherwise it saves and returns to Today.

### Acceptance Criteria

- Focus session is linked to schedule/task where available.
- Completion updates Review metrics.
- User never sees unrelated planning UI while focusing.
- Completing a session clearly answers what happened and what to do next.
- Writing a reflection does not inflate actual focus minutes.

## Module 7: Review

### User Goal

Understand what happened today and how to plan better next time.

### Core Data

- Focus sessions.
- Completed count.
- Focus duration.
- Mood entries.
- Today or this-week schedule blocks.
- Review range selection.
- Weekly day-by-day rhythm stats.
- Schedule change history.
- Deleted schedule archive.
- Carry-over records.
- Planned vs actual duration.
- Later: project/tag distribution, weekly review.

### Required Functions

- Show narrative summary.
- Switch between today and this week.
- Show focus hours.
- Show completion rate.
- Show mood average.
- Show completed schedule blocks.
- Show plan changes: delay, advance, edit, delete.
- Treat carry-over as a reviewable plan change.
- Show estimate accuracy text from actual vs planned minutes.
- Show recent change feed.
- Show lightweight weekly rhythm bars for planned minutes, focus minutes, completion, and changed days.
- Explain overload, conflicts, carry-over, routine-generated blocks, and estimate drift in short natural language.
- Give one practical recommendation for the next planning pass.
- Show an actionable empty-state guide when there is no reviewable data yet.
- Later: project/tag distribution and richer trend charts.

### UI Description

Top:

- `Review` title.
- Human explanation.
- Segmented `今天 / 本周` range switch.

Narrative panel:

- A readable summary, not just metrics.
- A compact recommendation strip that tells the user what to adjust next.

Stats panel:

- Focus hours.
- Completion ring.
- Completion/session/mood metrics.

Weekly rhythm panel:

- Visible in the `本周` scope.
- Seven compact day rows.
- Muted planned bar and fresh-green focus bar.
- Completion count and change signal on the right.

Next insights:

- Shows key insight rows for overload, conflict, carry-over, routine usage, and estimate drift.

Empty review state:

- Replaces zero-heavy analytics with a short explanation.
- Offers direct actions to collect a task or open planning.
- Keeps Review from feeling broken before the user has created a timeline.

### Acceptance Criteria

- Review starts with interpretation.
- Review can explain both today's execution and this week's rhythm.
- Weekly review remains glanceable; it should not become a dense analytics dashboard.
- Metrics answer practical planning questions.
- Review uses real execution and schedule-change data, not placeholder ideas.
- Review explains why the day felt stable or messy, not only whether tasks were completed.
- With no review data, the page shows next actions instead of a stack of zero-value analytics.

## Module 8: Schedule Editing

### User Goal

Adjust plans without deleting and recreating time blocks.

### Required Functions

- Edit title.
- Edit date.
- Edit time.
- Edit duration.
- Use DatePicker and TimePicker style controls instead of fixed time chips.
- Delay/advance.
- Change note field for manual edits.
- Quick delay/advance actions auto-fill a change note if none is provided.
- Delete block.
- Store schedule change history on edited schedules.
- Archive deleted schedule blocks for Review.
- Detect whether the edited block will overlap another active block.
- Later: drag timeline blocks.

### UI Description

- Bottom sheet from Today timeline block.
- Header shows block title and status.
- Quick buttons: advance 15m, delay 30m, tomorrow 09:00, delete.
- Change note appears before saving delay/advance.
- Inline conflict warning appears while choosing date, time, or duration.
- Date and end time are selected through compact picker controls.

### Acceptance Criteria

- User can move a block in under 10 seconds.
- Changes are recorded for Review.
- Deleted blocks still appear in Review as archive entries.
- Conflict warnings do not block saving, but make overlap visible before confirmation.
- Custom date/time choices are not limited to a few preset chips.

## Module 9: Reminder Engine

### User Goal

Receive real reminders at the right time.

### Required Functions

- Store reminder rules.
- On time / before due / custom offset.
- Settings stores notification, sound, and vibration preferences without claiming real delivery.
- Later: real HarmonyOS notification/alarm integration after official capability review.

### UI Description

- Reminder selection appears in schedule sheets.
- Settings page explains that reminder preferences are saved, but real system reminder delivery requires official capability review and device verification.

### Acceptance Criteria

- No fake reminder behavior is claimed.
- Real reminder delivery only ships after official system API confirmation.

## Module 10: Projects, Tags, And Contexts

### User Goal

Organize beyond today without overwhelming daily planning.

### Required Functions

- Projects/lists.
- Tags/contexts.
- Filter by project/tag.
- Show project workload.
- Later: custom project colors.

### UI Description

- Secondary library view, not primary daily surface.
- Tags are small chips.
- Project colors are accents, not full backgrounds.

### Acceptance Criteria

- Daily planning remains simple.
- Users can find long-term tasks quickly.

## Module 11: Routines And Habits

### User Goal

Avoid recreating repeated daily blocks.

### Required Functions

- Routine templates.
- First version: default templates can be added from Today with one tap.
- Repeat rules.
- Auto-generate schedule blocks.
- Habit completion.
- Later: habit streaks.

### UI Description

- Routines appear as soft green timeline blocks.
- Today shows only a compact routine strip, not a separate routine management page.
- Each template shows time, duration, and a short purpose.
- Habit state should be calm, not gamified aggressively.

### Acceptance Criteria

- A default routine template can create today's task and schedule block in one tap.
- The same template is not offered twice on the same day after it is scheduled.
- A routine can create future blocks without manual duplication.

## Module 12: Settings

### User Goal

Control defaults without cluttering planning.

### Required Functions

- Default focus duration.
- Default rest duration.
- Default daily capacity.
- Compact product mainline summary.
- Reminder toggles.
- Capability status card for core flow, local data, system reminders, and release signing.
- Experience status card for static build, device QA, system reminder, and signing readiness.
- Local data status counts.
- Theme preference.
- Data reset/export later.

### UI Description

- Quiet list groups.
- Mainline card shows `收集 / 安排 / 专注 / 复盘` as a short visual sequence.
- Local data card shows schema version and counts for task, schedule, focus, and archive records.
- Experience status card uses honest pre-release wording and does not imply full release readiness.
- Focus group includes default focus, default rest, and daily capacity.
- Daily capacity clamps to a practical range before saving.
- No promotional content.
- Settings stays secondary.
- System-capability copy must be honest about features that are preferences only.

### Acceptance Criteria

- Default focus duration affects new schedules and standalone focus sessions.
- Daily capacity affects Today and Plan workload warnings.
- Mainline summary stays concise and does not become a tutorial page.
- Local data status is read-only until export/import permissions are reviewed.
- Reminder preference toggles do not imply real system reminder delivery.
- About uses experience-version wording until device QA and signing are complete.

## Module 13: Data And Migration

### User Goal

Keep local data stable as the app evolves.

### Required Functions

- Preferences persistence.
- Model versioning.
- Safe optional fields.
- Migration from older task/schedule records.
- Later: export/import.

### Current Implementation

- `DataManager.init()` runs migration after Preferences initialization.
- `DataMigration` defines the current local schema version and normalizes older records for mood entries, tasks, schedules, archives, focus sessions, rest sessions, settings, and user info.
- `StorageKeys.DATA_SCHEMA_VERSION` records the applied schema version in Preferences.
- Migration keeps old optional fields safe while supplying defaults for fields added during the product rebuild, such as task steps, schedule state, routine linkage, actual minutes, and user capacity settings.

### Acceptance Criteria

- Existing unversioned local data can still load after new optional fields are added.
- New installs receive a schema version without user-facing setup.
- Future entity work adds a migration step before relying on new required fields.

## Module 14: Navigation And Route Boundary

### User Goal

Move between Today, Inbox, Plan, Future, Review, Settings, and Focus without dead buttons or confusing route behavior.

### Required Functions

- Use official `UIContext.getRouter()` navigation instead of deprecated global router calls.
- Keep page jumps centralized through `NavigationManager`.
- Keep Focus route params explicit and typed: duration, schedule id, task id, and auto-start.
- Keep navigation failures contained so a failed jump does not crash the current page.
- Show a short startup loading state until local Preferences and theme initialization complete.
- Preserve the Today-first product flow: Today -> Inbox, Today -> Plan, Today/Plan -> Focus, Focus -> Today or next Focus.
- Keep bottom-tab glyphs distinguishable so Future and Review do not look like the same destination.

### UI Description

- Navigation should feel invisible; the user sees clear buttons, not route mechanics.
- Startup loading state should be calm and short, with no decorative marketing copy.
- Back actions use compact icon buttons in secondary pages.
- Bottom tabs use distinct labels and glyphs for Today, Inbox, Plan, Future, and Review.
- Focus handoff buttons clearly say whether they start a block, return to Today, or start the next block.

### Acceptance Criteria

- No app page uses deprecated global `router.pushUrl`, `router.back`, or `router.getState`.
- `NavigationManager` is the default place for page navigation.
- Route parameter object literals have explicit ArkTS types.
- Build output no longer reports router deprecation warnings.
- First mounted app tabs do not read local Preferences before `DataManager.init()` completes.
- Future and Review use different tab glyphs.

## Current Implementation Priority

P0 sequence:

1. Make every visible button perform a real action.
2. Deepen Today timeline: now indicator, free space, editable blocks.
3. Make Inbox triage complete: today, tomorrow, custom schedule, note, delete.
4. Make Plan interactive, not only descriptive.
5. Add schedule edit sheet with delay/advance and change notes.
6. Make Review reflect actual deferrals and estimate accuracy.

## Definition Of Done For Any Module

- UI matches Fresh Graphite Timeline language.
- All visible buttons either work or are clearly disabled.
- Page navigation uses `NavigationManager` and UIContext Router.
- Data persists locally.
- Empty states explain the next action.
- `assembleApp --no-daemon` passes.
- Progress docs are updated.
