# Flow State Product Roadmap

Updated: 2026-05-12

This roadmap is the product backlog for building Flow State into a polished HarmonyOS planning app. It combines the current project state, the feature list from `副本任务类功能.xlsx`, HarmonyOS/ArkTS implementation constraints, and patterns from mature planning apps.

## Product Direction

Flow State should not be "another checklist app." The product direction is:

- A daily planning app that combines tasks, time blocking, focus sessions, and gentle review.
- Simple on the surface, structured underneath.
- Fast enough for quick capture, calm enough for daily use, and visually refined enough to feel like a real product.
- Minimal UI, but not empty UI: every page should have hierarchy, useful context, and a clear next action.

Design principle: **简约而不简单**.

- Show one primary decision at a time.
- Hide complexity behind detail sheets, progressive disclosure, and sensible defaults.
- Use quiet color, precise spacing, good empty states, and meaningful micro-interactions.
- Avoid demo-like cards, fake AI claims, loud gradients, excessive roundness, and decorative UI that does not help planning.

## Market References

These are not products to copy directly. They are reference points for mature planning behavior.

| Product | Useful Patterns For Flow State | Source |
| --- | --- | --- |
| TickTick | Pomodoro, habit tracking, Eisenhower matrix, countdowns, timeline-style scheduling, task duration adjustment. | https://ticktick.com/features |
| Todoist | Quick add, recurring due dates, reminders, priorities, projects, labels, descriptions, sections, subtasks, Today/Upcoming, filters, list/calendar/board views, productivity history. | https://www.todoist.com/features |
| Microsoft To Do | My Day, lists, due dates, reminders, starred important tasks, steps, notes, Outlook task sync concept. | https://support.microsoft.com/en-us/office/get-started-with-microsoft-to-do-d6846e1a-b922-46ea-bbab-c259cfa1cd9d |
| Any.do | Daily planner, calendar, widgets, reminders, recurring/location reminders, shared lists, notes/files, all-in-one task/calendar flow. | https://www.any.do/ |
| Structured | Visual timeline, inbox capture, calendar + tasks + routines, subtasks/notes, Pomodoro, custom notifications, automatic replanning. | https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946 |
| Sunsama | Guided daily planning, workload estimate, timeboxing, focus mode, rollover, daily shutdown/weekly review rituals. | https://help.sunsama.com/docs/daily-planning |
| Taskito / Sorted | Timeline-first daily planning, calendar-task unification, recurring tasks, reminders, hyper-scheduling. | https://taskito.io/ and https://www.sortedapp.com/ |

## Current Product Snapshot

Done:

- Cold, restrained visual direction replacing the previous yellow-heavy look.
- Core tabs: Tasks, Home, Records.
- Focus page.
- Settings page.
- Basic local data persistence with Preferences.
- Task and schedule model.
- Date choice, time point choice, reminder choice.
- Schedule status: planned, ongoing, overdue.
- Basic priority sorting.
- Basic focus session logging.
- Basic mood check-in and record dashboard.

Still weak:

- No real task detail model yet: notes, subtasks, tags, recurrence, and change history are missing.
- No proper daily timeline yet; current task page is a list/workbench, not a time-block planner.
- Reminder UI exists, but real OS reminder delivery still needs official HarmonyOS capability verification and implementation.
- Records page is cleaner but not yet insightful enough.
- Home page is cleaner but still needs richer composition and better "what should I do next?" intelligence.
- UI is more coherent than before, but still needs finer spacing, hierarchy, empty states, transition states, and iconography.

## Feature Status Legend

- `Done`: implemented and compiled.
- `Partial`: some UI/data exists, but the feature is not product-complete.
- `Planned`: should be implemented in a near or mid-term phase.
- `Research`: requires official HarmonyOS documentation confirmation before implementation.
- `Later`: useful, but not needed for the next usable version.

Priority:

- `P0`: next product-quality baseline.
- `P1`: important differentiator after baseline.
- `P2`: advanced feature or later polish.

## Detailed Feature Backlog

### A. Information Architecture

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| IA-01 | Today dashboard | Partial | P0 | Home now has current state, mood, quick start, and next-action card; still needs smarter workload insight. | User can open the app and immediately know what to do next. |
| IA-02 | Plan / task workbench | Partial | P0 | Task page now combines overview, quick capture, today timeline, and task cards; still needs detail sheets. | User can create, arrange, and start work without leaving the page. |
| IA-03 | Inbox | Partial | P0 | Unscheduled quick-capture tasks are now represented as Inbox count and task cards without schedules. | User can add unscheduled tasks in one step and later schedule them. |
| IA-04 | Task detail sheet | Partial | P0 | Bottom sheet now supports title, priority, notes, subtasks, and scheduling. Tags/history still pending. | Task cards stay minimal, but all task depth is available on tap. |
| IA-05 | Search | Planned | P1 | Search tasks, notes, tags, and completed history. | User can find an old task or note quickly. |
| IA-06 | Calendar/timeline tab or mode | Planned | P1 | Daily timeline first; weekly/month calendar later. | User can switch between list and time layout. |
| IA-07 | Navigation polish | Partial | P0 | Bottom tab needs stronger selected state, spacing, and haptic/visual feedback. | Tabs feel native, stable, and premium. |

### B. Task Capture

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| CAP-01 | Quick add | Partial | P0 | Task page has a fast capture field that creates an unscheduled Inbox task. Floating/global entry still pending. | User can add a task title without filling a long form. |
| CAP-02 | Natural language time parsing | Planned | P1 | Parse phrases like "明天 9 点 背单词 30 分钟". | Common Chinese time expressions become date/time/duration fields. |
| CAP-03 | Smart defaults | Planned | P0 | Default time, default reminder, and default duration based on settings. | Form opens with sensible values and fewer taps. |
| CAP-04 | Inbox capture | Partial | P0 | Quick capture creates unscheduled tasks; detail sheet can now schedule an Inbox task into the timeline. Global Inbox view still pending. | User can capture ideas without planning immediately. |
| CAP-05 | Task templates | Later | P2 | Reusable templates for study, workout, review, chores. | User can create repeated structures quickly. |
| CAP-06 | Voice input entry | Later | P2 | Optional voice-to-task flow if HarmonyOS support is verified. | User can speak a task into Inbox. |

### C. Task Model

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| TASK-01 | Task title / priority | Done | P0 | Detail sheet supports editing title and priority after creation. | User can edit title and priority after creation. |
| TASK-02 | Subtasks / checklist | Partial | P0 | Detail sheet supports adding, checking, and deleting subtasks. Reordering still pending. | Task detail supports adding, checking, reordering subtasks. |
| TASK-03 | Notes | Done | P0 | Detail sheet has a persisted notes field for context and requirements. | Task detail has a notes field persisted locally. |
| TASK-04 | Tags / contexts | Planned | P1 | Labels like study, work, home, waiting, deep work. | User can filter or group by tags. |
| TASK-05 | Projects / lists | Planned | P1 | Organize tasks by areas such as study, personal, health. | User can create lists and assign tasks. |
| TASK-06 | Recurring tasks | Planned | P0 | Daily, weekly, monthly, custom repeat rules. | Repeating task instances appear automatically. |
| TASK-07 | Task status lifecycle | Partial | P0 | Planned, ongoing, completed, overdue, postponed, archived. | Status is consistent across UI, records, and sorting. |
| TASK-08 | Completion history | Planned | P0 | Store completedAt, actual duration, pauses, reflection. | Records can show completion trends accurately. |
| TASK-09 | Attachments / files | Later | P2 | Notes/files are useful but not core for mobile MVP. | User can attach reference files if storage model supports it. |
| TASK-10 | Data migration versioning | Planned | P0 | Model changes need compatibility with old local data. | Existing users do not lose tasks after model updates. |

### D. Planning And Scheduling

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| PLAN-01 | Precise due time | Done | P0 | From xlsx: specific deadline and overdue state. | Schedule stores due timestamp and shows overdue. |
| PLAN-02 | Start time + duration | Partial | P0 | Existing duration and due time can derive interval, but needs explicit start/end model. | UI can show "09:00-09:30" clearly. |
| PLAN-03 | Date range / interval planning | Partial | P0 | From xlsx: support week/month/specific range. | User can schedule a task for a range, not only a single day. |
| PLAN-04 | Daily timeline | Partial | P0 | Task page now previews today's time blocks in order. Full edit/replan timeline is still pending. | User sees the day as time blocks, not only cards. |
| PLAN-05 | Week planner | Planned | P1 | Plan several days with a horizontal day strip or week view. | User can move tasks across days. |
| PLAN-06 | Month overview | Planned | P1 | Lightweight month calendar for deadlines and review. | User can see task density across the month. |
| PLAN-07 | Timebox editing | Planned | P1 | Adjust start time/duration from schedule detail. Drag can come later. | User can reschedule without deleting/recreating. |
| PLAN-08 | Delay / advance | Planned | P0 | From xlsx: dynamically adjust task execution time. | User can postpone or advance a schedule in two taps. |
| PLAN-09 | Change note | Planned | P0 | From xlsx: record why time changed. | Every delay/advance can save a reason and timestamp. |
| PLAN-10 | Auto rollover | Planned | P0 | Unfinished tasks should move to tomorrow or Inbox with visible history. | Missed work does not disappear or pile up silently. |
| PLAN-11 | Workload estimate | Planned | P0 | Sunsama-like load estimate for planned minutes vs available time. | App warns when the day is overloaded. |
| PLAN-12 | Conflict detection | Planned | P1 | Detect overlapping time blocks. | User sees conflicts before saving. |
| PLAN-13 | Replan action | Planned | P1 | One action to move overdue/missed tasks into later slots. | User can recover a broken day calmly. |

### E. Reminders And Notifications

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| REM-01 | Reminder data model | Partial | P0 | Reminder minutes exist in UI/data. | Reminder config is stored per schedule/task. |
| REM-02 | Real time reminder | Research | P0 | From xlsx: trigger notification/alarm at scheduled time. Requires official HarmonyOS notification/alarm capability verification. | Device shows a real reminder at the right time. |
| REM-03 | Custom reminder rules | Planned | P0 | No reminder, on time, before due, custom offset, default reminder. | User can define reminder behavior per task. |
| REM-04 | Recurring reminders | Planned | P1 | Repeat reminders for recurring tasks/routines. | Recurring tasks notify correctly. |
| REM-05 | Snooze | Planned | P1 | Delay reminder by 5/10/30 min or tomorrow. | Notification and task state stay in sync. |
| REM-06 | Location reminders | Later | P2 | Todoist/Any.do style location triggers. Requires permission and product fit review. | User can set "arrive at library" reminder. |
| REM-07 | Notification settings | Partial | P0 | UI exists, but behavior must connect to real reminder service. | Settings actually affect notification behavior. |

### F. Focus Mode

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| FOCUS-01 | Focus timer | Done | P0 | Countdown/continuous timer exists. | User can start, pause, complete, cancel. |
| FOCUS-02 | Task-linked sessions | Partial | P0 | Schedule/task IDs can be passed into focus page. | Completed sessions reliably update task/schedule records. |
| FOCUS-03 | Planned vs actual time | Planned | P0 | Compare estimated and actual time. | Records show whether tasks were under/over-estimated. |
| FOCUS-04 | Rest timer | Planned | P1 | Rest interval after focus session. | User can start rest automatically or manually. |
| FOCUS-05 | Session reflection | Partial | P1 | Basic reflection exists, needs better review usage. | Reflection appears in task history and records. |
| FOCUS-06 | Focus mode refinement | Planned | P0 | Better visual states, progress, completion motion, interruption states. | Timer feels polished and calming. |
| FOCUS-07 | Live Window / background | Research | P1 | HarmonyOS-specific live status/background behavior needs official docs. | Timer remains useful outside app where supported. |
| FOCUS-08 | White noise / focus ambience | Later | P2 | Optional soundscapes, not core. | User can choose focus audio without clutter. |

### G. Records, Review, And Analytics

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| REC-01 | Basic stats | Partial | P0 | Focus time, completions, average mood exist. | Stats are accurate and consistent. |
| REC-02 | Task completion distribution | Planned | P0 | Completion by priority/project/tag. | User can see where effort goes. |
| REC-03 | Focus trend chart | Planned | P0 | Daily/weekly/monthly focus bars. | User can see focus trend at a glance. |
| REC-04 | Mood trend and correlation | Partial | P1 | Current mood trend exists, but not linked to task/focus outcomes. | App can show focus vs mood relationship. |
| REC-05 | Review timeline | Planned | P1 | Recent sessions with task names, durations, reflections. | Records page tells a readable story. |
| REC-06 | Weekly review | Planned | P1 | Ritual: wins, unfinished, trends, next week. Inspired by Sunsama. | User can review week in under 3 minutes. |
| REC-07 | Streaks and consistency | Planned | P1 | Completion streaks for focus/habits. | User sees habit-building feedback without gamification clutter. |
| REC-08 | Export data | Later | P2 | Export tasks/sessions as JSON/CSV. | User can keep personal data. |

### H. Habits And Routines

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| HAB-01 | Routine tasks | Planned | P1 | Morning/evening/study routines with recurring blocks. | User can reuse routine structures. |
| HAB-02 | Habit tracker | Planned | P1 | TickTick-like habit tracking, but visually quieter. | User can check habits and see streaks. |
| HAB-03 | Routine templates | Later | P2 | Prebuilt templates for study, workout, review. | User can create routine quickly. |
| HAB-04 | Habit analytics | Later | P2 | Completion rate, streak, mood relation. | Habits appear in records. |

### I. Calendar And External Integration

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| CAL-01 | In-app calendar view | Planned | P1 | Date/week/month planning view inside app. | User can browse dates without external calendar. |
| CAL-02 | Calendar event import | Research | P1 | Import local/system calendar events if HarmonyOS API allows. | Timeline shows events next to tasks. |
| CAL-03 | Calendar export/timeboxing | Research | P2 | Create calendar events from task timeboxes. | Planned work appears in external calendar. |
| CAL-04 | Cross-device sync | Later | P2 | Requires account/cloud strategy. | Tasks sync across devices. |

### J. UI / UX Quality

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| UX-01 | Design token system | Partial | P0 | Centralize colors, spacing, typography, radii, shadows. | Pages stop hardcoding repeated visual values. |
| UX-02 | Component system | Planned | P0 | Primary button, secondary button, stat tile, section header, task row, timeline block, dialog. | UI consistency comes from reusable builders/components. |
| UX-03 | Visual density pass | Planned | P0 | More content per screen without clutter. | Screens feel premium, not empty. |
| UX-04 | Micro-interactions | Planned | P1 | Press states, selected states, subtle transitions where ArkUI supports them. | UI feels alive but not noisy. |
| UX-05 | Empty states | Partial | P0 | Useful empty states for inbox, timeline, records, no mood, no focus. | Empty screens guide the next action. |
| UX-06 | Swipe actions | Planned | P1 | Complete, postpone, delete, start from task rows if ArkUI pattern is verified. | Frequent actions become fast. |
| UX-07 | Detail sheets/dialog refinement | Planned | P0 | Current dialogs work, but need polish and hierarchy. | Creation/editing feels deliberate and not form-heavy. |
| UX-08 | Dark mode | Planned | P1 | True app-wide dark mode, not only Focus page. | Theme switch visibly changes all surfaces. |
| UX-09 | Accessibility | Planned | P1 | Text scale, contrast, screen reader labels, touch target sizes. | App remains usable with larger text and accessibility tools. |
| UX-10 | Visual identity | Planned | P1 | App icon, launch/splash, refined tab icon style, subtle brand marks. | App feels complete outside the main pages too. |

### K. Settings And Data

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| DATA-01 | Settings persistence | Partial | P0 | Basic user settings exist. | Every setting has visible behavior. |
| DATA-02 | Default reminder settings | Planned | P0 | Default reminder offset, sound/vibration. | New tasks inherit settings. |
| DATA-03 | Data reset | Planned | P1 | Reset app data with confirmation. | User can clear local data safely. |
| DATA-04 | Backup/export | Later | P2 | JSON/CSV export. | User can move or archive data. |
| DATA-05 | Storage migration | Planned | P0 | Required as task model grows. | App can upgrade old data safely. |
| DATA-06 | Privacy note | Planned | P1 | Explain local data and notification use. | Settings includes clear data policy. |

### L. HarmonyOS Native Capabilities

These require official HarmonyOS documentation verification immediately before implementation.

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| HMOS-01 | System notification reminders | Research | P0 | Use official notification APIs and permissions. | Reminder fires reliably on device. |
| HMOS-02 | Background timer behavior | Research | P1 | Verify supported background task model. | Focus timer behaves correctly when app backgrounded. |
| HMOS-03 | Live Window / live status | Research | P1 | Only if supported by official docs and device target. | Active focus session can be surfaced outside app. |
| HMOS-04 | Widget/card | Research | P1 | Quick glance for today, next task, start focus. | User can see next action from launcher/widget surface. |
| HMOS-05 | Calendar provider integration | Research | P2 | Calendar import/export depends on available APIs and permissions. | Events/tasks can interoperate with calendar. |

### M. Smart Assistance

AI should be useful, not decorative.

| ID | Feature | Status | Priority | Details | Done When |
| --- | --- | --- | --- | --- | --- |
| SMART-01 | Rule-based suggestions | Planned | P1 | Suggest focus duration based on mood, workload, and task length. | Suggestions are explainable and useful. |
| SMART-02 | Daily planning assistant | Later | P2 | Turn a goal list into a draft day. | User can accept/edit generated schedule. |
| SMART-03 | Auto replan | Planned | P1 | Move missed tasks intelligently based on available slots. | Broken day can be recovered with one reviewed action. |
| SMART-04 | Natural-language quick add | Planned | P1 | Parse text locally/rule-based first. | User can type natural Chinese and get structured fields. |

## Recommended Phased Execution

### Phase 4: "简约而不简单" UI Refinement

Goal: make the current UI feel more complete without adding large backend complexity.

Scope:

- Build a shared design token/component layer for repeated colors, buttons, rows, cards, badges, and section headers.
- Refine Home with "next action" card and richer dashboard composition.
- Refine Task page density and hierarchy; make cards easier to scan.
- Refine dialogs into cleaner task/detail sheets.
- Add polished empty states and selected/pressed states.

Acceptance:

- No page feels like a demo.
- Every screen has one obvious primary action.
- Visual language is consistent across Home, Tasks, Records, Focus, Settings.
- `assembleApp --no-daemon` passes.

### Phase 5: Task Detail, Subtasks, Notes, And Change History

Goal: make task data useful enough for real daily planning.

Scope:

- Add TaskDetail sheet.
- Add notes, subtasks, edit title/priority/time.
- Add delay/advance with change note from the xlsx.
- Add task status lifecycle and completion timestamp.
- Add data migration for old tasks.

Acceptance:

- User can plan and modify a task without deleting/recreating it.
- Delay/advance records a reason and appears in task history.

### Phase 6: Timeline Planning

Goal: move from a task list to a true day planner.

Scope:

- Add daily timeline blocks.
- Show start/end time and duration clearly.
- Support Inbox -> schedule flow.
- Add workload estimate and overloaded-day warning.
- Add auto rollover for missed tasks.

Acceptance:

- User can visually understand the whole day.
- Unscheduled and missed tasks have a clear place to go.

### Phase 7: Real Reminders And Recurrence

Goal: make the app dependable.

Scope:

- Verify official HarmonyOS notification/reminder APIs.
- Implement real reminder scheduling.
- Add default reminder settings.
- Add recurring task rules.
- Add snooze.

Acceptance:

- Scheduled reminder fires on real device/emulator where supported.
- Recurring tasks generate correctly.

### Phase 8: Records, Review, Habits

Goal: make the app rewarding over time.

Scope:

- Add focus trend chart.
- Add completion by priority/project.
- Add weekly review.
- Add habit/routine tracker.
- Connect mood, focus, and completion insights.

Acceptance:

- Records page tells the user something useful, not just raw numbers.

### Phase 9: HarmonyOS Native Polish

Goal: make it feel like a native HarmonyOS app.

Scope:

- Widget/card if official APIs and project target support it.
- Live Window or background focus status if officially supported.
- Accessibility pass.
- App icon/launch polish.
- Privacy/data page.

Acceptance:

- App feels native outside the main screen, not just inside pages.

## Next Implementation Recommendation

The next best phase is **Phase 4: UI Refinement**.

Reason:

- The user already noticed the UI is better but still too simple.
- Before adding more complex functionality, the component system needs to be clean.
- A shared visual system will make every future feature easier and prettier to implement.

Concrete next tasks:

1. Extract common UI builders/components: section title, stat block, primary/secondary button, compact chip, empty state, task row.
2. Refine Home into a more premium dashboard with a stronger "next action" surface.
3. Refine Task page into a denser daily planner surface.
4. Improve add/edit dialogs into cleaner sheets.
5. Keep the current graphite/fog/teal palette but add depth through layout, typography, and state design instead of more colors.
