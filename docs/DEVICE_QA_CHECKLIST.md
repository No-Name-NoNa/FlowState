# Flow State Device QA Checklist

Updated: 2026-05-16

This checklist is the final runtime pass for the HarmonyOS app. Static builds can pass while tap behavior, keyboard placement, picker height, and route stack still fail on device, so this checklist must be completed before calling the app release-ready.

## Current Status

- Build status: `hvigor assembleApp --no-daemon` passes.
- HDC tool path: `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe`.
- Latest known HAP path: `flow/build/default/outputs/default/app/flow-default.hap`.
- Current blocker: `hdc list targets -v` returns empty in this workspace, so no HarmonyOS phone or emulator target is currently available.
- Signing status: release signing is still not configured in `build-profile.json5`; current build warnings are expected until signing is prepared.
- Release handoff details: `docs/RELEASE_HANDOFF.md`.

## Device Setup

1. Start a HarmonyOS phone emulator in DevEco Studio, or connect a HarmonyOS phone with debugging enabled.
2. Confirm the device is visible:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' list targets -v
```

3. Build the app:

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

4. Install and launch the latest generated HAP from `flow/build/default/outputs/default/`.

## Core Runtime Walkthrough

### 1. Today First Impression

- First launch may briefly show `正在准备本地数据`; it should disappear quickly.
- App opens on `今天`.
- Workload band is visible without awkward clipping.
- Next action says one of: collect, arrange, start, or review.
- Settings button opens Settings and returns without breaking the tab stack.

### 2. Collect

- Add a task in `收集`.
- Empty-title button does not create a task.
- `今天` creates a Today time block and removes the task from Inbox.
- `明天` moves the task to `未来` and does not look like data loss.
- `整理` opens the detail sheet, and keyboard does not cover primary actions.

### 3. Plan

- `可安排来源` shows Inbox count, future schedule count, and today planned minutes.
- A future item can be moved into Today from Plan.
- With an empty Inbox and at least one future item, Plan's primary action offers to move future work into Today.
- Auto-plan suggestions can be selected, excluded, restored, reordered, and resized.
- Applying suggestions creates non-overlapping Today blocks.
- Handoff panel can start the first block directly.

### 4. Today Timeline

- Blocks appear in chronological order.
- Free-space rows and now indicator do not overlap text.
- Editing a block can change title, date, time, duration, priority, note, and subtasks.
- Quick actions: advance, delay, move to tomorrow, complete, and delete.
- Conflict banner appears for overlapping active blocks.

### 5. Focus

- Focus opened from Today or Plan receives schedule/task context.
- Start, pause, resume, complete, and abandon work.
- Completion freezes actual minutes before reflection text is entered.
- If another block exists, `开始下一段` starts it with the correct context.

### 6. Future

- Tomorrow, this-week, and later groups show expected items.
- A future item can move to Today.
- A future item can return to Inbox without deleting the task.
- Future editor preserves linked task notes and subtasks.

### 7. Review

- Empty Review shows the guide instead of zero-heavy analytics.
- Today/Week switch changes the report without visual jumping.
- Review reflects focus sessions, completions, schedule edits, deletions, carry-over, conflicts, and estimate drift.

### 8. Settings

- Default focus duration affects new schedules.
- Daily capacity affects Today and Plan workload warnings.
- `体验状态` clearly shows build, device QA, system reminder, and signing readiness.
- Reminder preference copy remains honest: preferences are stored, real system delivery is not claimed.
- Local data status shows schema version and data counts.
- About card uses experience-version wording until release signing and device QA are complete.

## Small-Screen Checks

- No primary button is hidden by a sheet or keyboard.
- Text inside buttons fits in Chinese.
- Bottom tab labels remain readable.
- DatePicker and TimePicker controls have enough vertical space.
- Sheets can be closed without saving.

## Pass Criteria

- The full loop works: collect -> schedule -> focus -> complete -> review.
- No visible button is dead or misleading.
- No scheduled task appears to disappear without explanation.
- No key sheet is unusable on a small-phone viewport.
- `assembleApp --no-daemon` still passes after any runtime fixes.
