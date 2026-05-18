# Flow State Product And UI Blueprint

Updated: 2026-05-12

This document resets the product direction. The current app should no longer be treated as a UI polish exercise on top of the first version. It should become a timeline-first daily planning app that borrows the best ideas from TickTick, Structured, Sunsama, Any.do, and Todoist while staying native to HarmonyOS ArkTS/ArkUI.

For the complete module-by-module product context, use `docs/FUNCTION_MODULE_SPEC.md` as the authoritative implementation reference.

## Reference Extraction

| Product | What To Learn | Source |
| --- | --- | --- |
| TickTick | Fast capture, NLP time input, reminders, recurring rules, calendar views, timeline view, Pomodoro, habits, statistics, themes. | https://ticktick.com/features |
| Structured | The day is one visual timeline. Inbox catches loose thoughts. Notes/subtasks/focus timer live around the timeline. Replan and routines reduce overwhelm. | https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946 |
| Sunsama | Guided daily planning ritual: reflect, choose tasks, check workload, finalize order, start the day. Workload warnings are a core quality feature. | https://help.sunsama.com/docs/usage-guides/daily-planning/ |
| Any.do | My Day style planning, task/calendar/reminder unification, simple cross-device mental model, strong quick review flow. | https://www.any.do/daily-planner/ |
| Todoist | Natural-language quick add, Inbox, Today/Upcoming, projects, labels, descriptions, subtasks, filters, flexible views, productivity history. | https://www.todoist.com/features |

## New Product Positioning

Flow State is not a generic task list.

Flow State is a calm, timeline-first personal planning app for people who want to turn scattered tasks into a realistic day plan, then focus on one thing at a time.

The product should feel:

- Calm, not childish.
- Structured, not overloaded.
- Premium, not decorative.
- Useful at first launch, deeper after repeated use.
- More like a personal operating dashboard than a checklist.

## What To Abandon From The Current Baseline

- Do not keep "Home / Task / Records" as three equally important abstract tabs. The primary surface should be Today.
- Do not make cards the dominant visual idea. Cards are tools for grouped content, not the page language.
- Do not rely on a single blue/teal palette everywhere. The app needs controlled color accents for task identity, status, energy, and priority.
- Do not show fake AI panels, generic slogans, or decorative metrics.
- Do not let task creation require a full form by default.
- Do not make Records a static stats page. It should become review and insight.
- Do not make Settings visually equal to product surfaces. Settings should be quiet and secondary.

## Core Information Architecture

### 1. Today

Primary tab and first screen.

Purpose: answer "What should I do now, what comes next, and is today realistic?"

Required modules:

- Day header: date, day progress, planned workload, remaining workload.
- Next action: the current/next time block with one primary Start button.
- Timeline: chronological blocks for tasks, routines, calendar events, breaks, and free space.
- Inbox strip: unscheduled tasks that can be dragged/tapped into the day.
- Overload warning: visible when planned minutes exceed target capacity.
- Replan bar: appears when tasks are overdue, missed, or the day is overloaded.

UI shape:

- Full-height vertical timeline, not a stack of unrelated cards.
- Left time rail with hour labels and a subtle vertical guide.
- Time blocks with compact height based on duration.
- Time blocks may reveal linked task notes and the first one or two subtasks when the task needs execution context.
- Inline task-depth controls should stay lightweight: subtask chips are acceptable; full editing belongs in a sheet.
- Color should identify task category/status, not fill the whole screen.
- "Now" indicator line should make the app feel alive.
- Empty states should offer action: Capture, Plan, or Import.

### 2. Inbox

Purpose: capture without organizing.

Required modules:

- One-line quick capture.
- Natural-language capture later: "明天 9 点 背单词 30 分钟".
- Unscheduled list grouped by age: Today, This Week, Older.
- Quick actions: schedule today, schedule tomorrow, add note, delete.
- Triage mode: process one item at a time into schedule, project, or archive.

UI shape:

- Looks like a calm stack of slips, not a heavy table.
- Each item shows title, optional detected date/time, priority dot, and source.
- Bottom capture bar always reachable.

### 3. Plan

Purpose: guided daily planning like Sunsama, not manual list management.

Required flow:

1. Review yesterday: unfinished, completed, carried-over.
2. Pick tasks: from Inbox, routines, projects, upcoming deadlines.
3. Estimate workload: planned minutes vs available capacity.
4. Order the day: drag or tap to arrange.
5. Finalize: create timeline and start first focus block.

UI shape:

- Stepper/wizard, but visually lightweight.
- One decision per screen.
- Source panel should show Inbox and scheduled-later work before auto-planning.
- Auto-plan is a proposal, not a command: suggestions should be selectable, excludable, and reversible before they become real time blocks.
- Suggested plans should be refinable in place: order and duration are part of the decision, not hidden in a later edit screen.
- Finalizing the plan should not dump the user back into a list; it should surface the first executable block and make starting it obvious.
- Persistent workload meter at bottom.
- "Too much" should be treated as a product feature, not a warning afterthought.

### 4. Task Detail

Purpose: keep the timeline clean while providing depth.

Required fields:

- Title
- Priority
- Notes
- Subtasks
- Schedule blocks
- Reminder rules
- Tags/context
- Project/list
- Repeat rule
- Change history

UI shape:

- Bottom sheet from timeline or Inbox.
- Header: title, priority, schedule status.
- Body sections are collapsible: Plan, Notes, Steps, Reminders, History.
- Primary action changes by context: Start, Schedule, Save, Complete.
- Inbox detail should let the user add notes and subtasks before deciding when to schedule the task.
- Scheduled blocks should keep showing enough task depth that the user understands what the block means after it leaves Inbox.
- Schedule editors may combine time controls with task-depth fields when the user is already editing that block; keep sections visually quiet and scrollable rather than forcing separate pages.
- When a schedule editor combines timing and task fields, timing remains the default visible task; note/priority/subtasks stay in a collapsible `任务细节` section.

### 5. Focus

Purpose: convert a plan into action.

Required modules:

- Linked task/schedule title.
- Countdown or count-up mode.
- Pause/cancel/complete.
- Reflection after completion.
- Planned vs actual duration.
- Next block preview.
- Completion handoff: return to Today or start the next block.

UI shape:

- Immersive, darker, low-distraction.
- Should not feel like a separate app.
- Completion should show planned/actual/delta, let the user write a short reflection, update the timeline, and either return to Today or start the next block.

### 6. Review

Purpose: make progress understandable.

Required modules:

- Daily review: completed, deferred, cancelled, focus time, mood.
- Weekly review: trends, overloaded days, most delayed tasks.
- Distribution: by project, priority, tag, time of day.
- Planning accuracy: estimated vs actual.

UI shape:

- More editorial and readable than dashboard-heavy.
- Charts should answer questions, not decorate.
- Start with "What happened today?" then allow deeper charts.
- If there is no reviewable data, show a concise next-step guide instead of zero-value analytics.

## Core Feature Set

### P0: Product Baseline

- Timeline-first Today view.
- Inbox capture.
- Task detail sheet.
- Subtasks and notes.
- Schedule a task into a date/time/duration block.
- Focus timer linked to schedule.
- Complete/defer/delete schedule blocks.
- Guided daily planning.
- Workload estimate.
- Basic review.
- Local persistence migration.

### P1: Mature Planning

- Natural-language quick add.
- Recurring tasks and routines.
- Delay/advance with change note.
- Auto rollover.
- Week planner.
- Tags/context.
- Projects/lists.
- Reminder rule engine.
- Existing schedule editing.
- Conflict detection.

### P2: Differentiators

- Energy estimate for tasks.
- AI-assisted plan draft after local data exists.
- Calendar integration after official HarmonyOS capability review.
- Live Window/background focus status after official docs review.
- Widgets.
- Export.
- Themes that remain tasteful.

## Core UI Language

### Visual Direction

Name: Fresh Graphite Timeline.

The app should look like a premium planner: quiet graphite text, soft off-white canvas, light mist surfaces, subtle separators, and controlled accent colors. It should not be monochrome. It should not become blue-only.

### Palette

Use semantic color, not decorative color.

- Canvas: `#F7F8F6`
- Surface: `#FFFFFF`
- Elevated surface: `#F0F4F3`
- Primary text: `#182126`
- Secondary text: `#62727A`
- Hairline: `#DDE5E3`
- Primary action: `#256D85`
- Focus teal: `#46AFA5`
- Calm green: `#7BAE7F`
- Attention slate: `#8EA1AE`
- Urgent slate: `#6F7F88`
- Lavender context: `#8A7CC3`
- Slate context: `#607385`

Rules:

- Do not use large yellow panels.
- Do not introduce saturated red into the blue/green system; urgent states should be low-saturation slate or muted clay at chip scale only.
- Do not use gradient blobs or decorative orbs.
- Most screens should be 70% neutral, 20% soft structural color, 10% accent.
- Time blocks can use tinted left rails or small chips; avoid full-card saturation.

### Typography

- Mobile headers: 26-30sp, bold, compact.
- Section titles: 16-18sp.
- Body: 13-15sp.
- Metadata: 10-12sp.
- No viewport-based font scaling.
- No oversized hero typography inside app screens.

### Layout Principles

- Timeline is the main composition.
- Use edge-to-edge sections with constrained inner padding.
- Cards only for repeated items, sheets, and real controls.
- Avoid nested cards.
- Primary cards should use a calm elevated treatment: off-white or deep slate fill, 1px hairline border, very soft shadow, and restrained radius.
- The current card direction is Layered Paper: outer cards use paper surfaces and soft lift; important values sit in inset paper tiles; active states use small accent rails or short top markers rather than full-card saturation.
- Important cards can contain quiet inner metric tiles or tonal action pills so they feel designed, not empty.
- Dark mode should be deep blue-gray, not pure black. Primary text must resolve to near-white, muted text to a readable blue-gray, and any light-only surface must use theme tokens instead of fixed pale colors.
- Editing sheets should avoid isolated picker blocks. Date/time controls should live inside a single schedule card with a clear selected summary.
- Destructive or completion actions should use the same rounded tonal button language as Focus controls, not raw flat color blocks.
- Do not use trailing-alpha CSS color strings in ArkUI. Translucent color strings in the app should use leading alpha to avoid accidental saturated colors.
- Stable dimensions for timeline blocks, icon buttons, tabs, and chips.
- Bottom sheets should be rounded modestly and occupy 80-92% height.
- Full-screen editing sheets must own the modal layer. When a detail sheet is open from Today, Inbox, or Future, the root bottom tab bar should be hidden instead of floating above the sheet.
- Keep the default path simple: show common actions first, then reveal advanced fields only when requested.
- Prefer progressive disclosure over showing every editable field at once.

### Motion And Interaction

Keep motion practical:

- Sheet enters from bottom.
- Timeline block pressed state darkens subtly.
- Completion collapses or fades into review, but does not celebrate loudly.
- Replan action should show visible before/after state.

No decorative animation until core product behavior is excellent.

## Target Screen Descriptions

### Today Screen

Top:

- Date and weekday.
- Workload pill: "3h 20m planned / 5h capacity".
- Small replan button if needed.

Support:

- A compact `常用模板` strip can appear near the top when routine templates are still available for today.
- Routine template rows must stay one-tap and low-commitment: title, time, duration, short purpose, `加入`.

Middle:

- Current block panel if there is active work.
- Otherwise next block panel.

Main:

- Vertical timeline from wake time to shutdown time.
- Blocks:
  - Routine blocks: soft green.
  - Deep work: blue/teal.
  - Admin: slate.
  - Personal: lavender.
  - Overdue: coral left rail.
  - Breaks/free space: outlined, light surface.

Bottom:

- Capture bar.
- Tab bar with Today, Inbox, Plan, Review.

### Inbox Screen

Top:

- "Inbox" title and count.
- Triage button.

Main:

- Unscheduled tasks grouped by Today / This week / Older.
- Each item supports tap for detail, quick schedule, and swipe/delete later.

Bottom:

- Persistent quick add field.

### Plan Screen

Top:

- Step indicator.
- Current planning stage.

Main:

- One focused decision:
  - Review unfinished.
  - Pick tasks.
  - Check workload.
  - Order timeline.
  - Finalize.

Bottom:

- Workload meter and next button.
- Source strip for Inbox and future work, with a simple move-to-today action.

### Review Screen

Top:

- Today / Week / Month toggle.

Main:

- Narrative summary.
- Focus time trend.
- Completion distribution.
- Estimate accuracy.
- Most delayed items.
- Empty-state guide with Collect and Plan actions before any timeline exists.

### Focus Screen

Direction:

- Treat Focus as the most immersive surface in the app, not another list page.
- Use a local natural landscape background with muted blue/green tones, translucent overlays, and glass-like panels.
- Keep hierarchy simple: back control, state title, linked task card, timer ring, one primary action, two secondary actions, and a compact rhythm strip.
- Typography should feel calm and iOS-like: larger timer numerals, softer metadata, rounded controls, and no loud red/orange interruption colors.
- Completion should not push stacked pages; returning to Today or starting the next block must preserve a shallow route hierarchy.

## Implementation Strategy

The next implementation should not keep patching the current screen order. It should migrate toward the new IA in controlled stages.

### Stage A: Navigation Reset

- Replace tabs with Today, Inbox, Plan, Review.
- Keep Settings accessible from Today header.
- Preserve existing data model and focus page for now.
- Current status: implemented. Root navigation now uses Today / Inbox / Plan / Future / Review, and old Home / Task / Records routes have been removed from the shipped page profile.

### Stage B: Today Timeline

- Move current task page timeline preview into a real Today page.
- Add time rail, now indicator, current/next action, free-space rows.
- Current status: implemented. HomePage is obsolete and removed from the routed app surface.

### Stage C: Inbox

- Create dedicated Inbox view from unscheduled tasks.
- Add triage and schedule action.

### Stage D: Plan Ritual

- Create guided daily planning flow.
- Add workload threshold.
- Support carry-over and defer.

### Stage E: Review

- Replace decorative records with review-first analytics.
- Add estimate vs actual once focus sessions are linked reliably.

## Acceptance Criteria

The app is moving in the right direction only when:

- Opening the app immediately shows today's timeline.
- A user can capture a task in under 3 seconds.
- A user can turn an Inbox item into a scheduled time block in under 10 seconds.
- A user can see whether today is overloaded.
- A user can start focus from the current/next block.
- The app has enough color to distinguish meaning, but still feels calm.
- No page looks like a demo placeholder.
- The roadmap and progress docs stay updated after every phase.

## Product Language Rules

- The app name is `流序`.
- User-facing priority language is `优先 / 重要 / 常规`; internal values such as `P0 / P1 / P2` must not appear in visible copy.
- Page copy should explain the next action, not the implementation. Avoid phrases such as sorting order, creation time, internal capacity logic, official verification, or placeholder/demo wording.
- Empty states should be short and task-oriented: tell the user what is true now and what they can do next.
- Settings may disclose limits, but the wording should stay product-facing and concise.
