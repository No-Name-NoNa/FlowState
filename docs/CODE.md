## FlowState - Development & Code Conventions

Updated: 2026-05-20
Core Principles: Pragmatic decoupling, reject over-engineering; keep code lightweight and ensure high maintainability.

I. Naming Conventions (Java Style Mapping)
--------------------------------------------------------------------
Strictly follow the intuitive habits of Java developers to ensure clear code semantics.

1. Classes & Interfaces:
   Strictly use PascalCase.
   Example: class TaskEngine, interface CompletionTrigger

2. Methods & Variables:
   Strictly use camelCase.
   Example: let timeArray, function calculateNextNode()

3. Constants & Enums:
   Use UPPER_SNAKE_CASE.
   Example: DEFAULT_FOCUS_DURATION, enum TaskPriority

4. State Decorator Variables:
   Variables under ArkTS decorators like @State and @Prop must maintain clear business semantics. Avoid excessive abbreviations.
   Example: @State isTaskRunning is preferred over @State running

5. Comments & Documentation:
   All inline comments and Javadoc-style block comments must be written in Chinese to facilitate seamless team collaboration and maintenance.

II. Architecture & Design Principles (Pragmatic Decoupling)
--------------------------------------------------------------------
Design patterns serve "ease of modification". It is strictly forbidden to create deep inheritance trees or complex interface factories just for the sake of applying patterns.

1. Strategy Pattern for Task Completion:
   For the various completion methods in the PRD (manual override, duration fulfilled, node reached), define lightweight interfaces implemented by different strategy classes. When adding a new deadline mechanism, just add a new implementation class without modifying the core engine.
   Example: interface CompletionStrategy, implementation class DurationCompletion.

2. Minimalist Dependency Injection:
   Do not introduce bloated IoC containers. Inject basic services (e.g., ReminderService) via constructors or initialization methods, making it easy to seamlessly replace the underlying reminder engine later.

3. Restrained Use of Singleton Pattern:
   Only keep absolutely necessary singletons globally (e.g., LocalDatabaseManager, GlobalTimerEngine). It is strictly forbidden to abuse singletons to pass business state data across layers.


III. ArkTS Formatting & Best Practices
--------------------------------------------------------------------
1. Strict Type Safety:
   Fully utilize ArkTS's strong typing features. Use interface and type to rigorously define the underlying time node array structure. The abuse of 'any' and 'unknown' is strictly prohibited.

2. Separation of View and Logic (MVVM Prototype):
   @Component internals should only retain view rendering code and minimal UI animation states. All logic involving time calculation, cycle postponement, and data persistence must be extracted into independent TypeScript/ArkTS classes (Service or ViewModel).

3. Shared State Management:
   Avoid deep, multi-level passing of @Prop within the component tree. For cross-layer task state updates, prioritize @Provide and @Consume. AppStorage can be used cautiously for global environment configurations (Keys must be declared in a unified configuration file).


IV. Assets & Visual Specifications
--------------------------------------------------------------------
1. Absolute Ban on Emojis:
   No emojis are allowed as UI elements or placeholders in the interface to ensure a professional look and cross-device consistency.

2. Native Icons First:
   Prioritize using HarmonyOS native system icon libraries (referenced using $r('sys.media.ohos_ic_...')).

3. Custom SVG Vectors:
   When system icons do not meet requirements, uniformly use the SVG format to draw them yourself and store them in the entry/src/main/resources/base/media directory to ensure they scale without distortion across multiple screen densities.

4. Decoupling Theme & Styles:
   Uniformly define Typography scales and borderless design transparency variables in ArkTS. It is strictly forbidden to hardcode specific color values and pixel-level borders inside components, facilitating future expansion for dark mode or custom background features.
