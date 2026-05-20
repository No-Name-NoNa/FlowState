## FlowState - Lightweight Focus & Task Management App (PRD)
Updated: 2026-05-20
Positioning: An ultra-lightweight, execution-driven engine based on dynamic priorities and the Flowtime core.
Rejecting bloated GTD planning and mandatory post-task reviews, returning to the shortest path of "Record - Execute - Complete".

I. Core Philosophy (Less is More)
--------------------------------------------------------------------
1. Abandon Fixed Scheduling: No mandatory "assign to a specific day" requirement; no algorithms that automatically pack the schedule.
2. No Deep Nesting: Eliminate the "Project -> Task -> Subtask" tree structure. All tasks are strictly flattened.
3. Remove Mandatory Reviews: Once a task is done, it's done. No forced summaries or reflections.
4. Seamless Interaction Hierarchy: Core operations are completed on the home screen (first screen). Reject bottomless waterfall scrolling.
5. De-block Visuals: Reject the overuse of cards and heavy color blocks. Strive for a transparent, light, and flat typographic layout.

II. Core Functional Modules
--------------------------------------------------------------------
1. Lightning-fast Capture (Inbox / Brain-dump)
   - Interaction: Global floating action button (FAB) or a persistent bottom input field on the home screen.
   - Behavior: Single-line plain text input, press enter to create a task instantly. Zero-friction temporary storage.
   - Extension: Properties like time, reminders, and recurrence are postponed as optional settings, ensuring the input flow is never interrupted.

2. Dynamic Scheduling List (Main Workspace)
   - Sorting Engine: (Urgency of Deadline) + (User-defined Priority) = Dynamic Weight.
   - Presentation: The most urgent and important tasks automatically float to the top of the list. No manual drag-and-drop scheduling required.

3. Unified Task Execution Engine (Unified Task Model)
   All tasks share the same underlying foundation. Point-in-time tasks are simply treated as interval tasks with an extremely short duration. They share the following termination and reminder mechanisms:
   - Reminder Triggers:
      * Strong Reminder: Requires manual intervention to dismiss (e.g., alarms).
      * Weak Reminder: System notifications, custom sound effects, device vibrations.
      * Silent Reminder: UI status highlight or icon color change only.
   - Completion Triggers:
      * Duration Fulfilled: Starts the built-in timer (Flowtime mode), automatically completes when the accumulated time reaches the goal.
      * Manual Override: One-click instant completion, overriding the current timer or remaining interval.
      * Node Reached: Directly settled as completed once a specific time point or reminder is triggered.

4. Task Lifecycle & Scheduling
   The underlying time attribute uses a "Date/Time Array" architecture, supporting flexible scheduling from minimalist to complex. The list interface strictly maintains a "Singleton Display" (showing only the nearest upcoming node):
   - Single One-off Task: Default format. Sets a single deadline/reminder time, dissipates and archives completely upon completion.
   - Multi-node Custom Task: Supports selecting multiple irregular dates on a calendar (e.g., Jan 10, Feb 5). Upon completing the current node, it automatically flows to the next node in the array.
   - Rule-based Recurring Task:
      * Absolute Recurrence: Hard-locked resets based on the natural calendar (e.g., the 1st of every month).
      * Relative Recurrence: Postponed based on the actual completion time (e.g., 3 days after completion).
      * Logic: After each completion, the system automatically calculates the next time based on the rule and pushes it into the scheduling queue.

5. Lightweight History Database
   - Recorded Items: Task name, configured properties, actual execution duration, completion time.
   - Presentation: Minimalist data dashboard (daily/weekly/monthly completion volume, total focused hours). Serves as an objective record for quick review.

III. Visual Experience & Technical Specifications
--------------------------------------------------------------------
1. UI/UX Design Language:
   - Core Principle: Cardless design. Avoid large areas of blocky elements with obvious borders and shadows.
   - Hierarchy Demarcation: Differentiate task levels through Typography (font size/weight), text color contrast, reasonable white space, and minimalist thin lines.
2. View Structure: Utilize horizontal Tab layouts or Bottom Sheets to completely eliminate bottomless vertical scrolling.
3. High Customizability:
   - Support custom global background colors and imported background images.
   - Paired with globally adaptive transparency adjustments and mask layers to ensure high readability of foreground text against any background.
4. Internationalization & Compatibility: The underlying architecture integrates i18n multi-language string management right from the initial release.
5. Smooth & Snappy Animations: Incorporate highly responsive transition animations. State changes and view switching must not be instantaneous (choppy) or sluggish. Aim for swift, fluid, and natural motions (e.g., rapid sliding or scrolling). All interactions must be ergonomic, intuitive, and human-centric.
