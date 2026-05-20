## FlowState - Development & Code Conventions

Updated: 2026-05-21
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

4. API Constraints — Divider.strokeWidth:
   The SDK declaration is strokeWidth(value: number | string): DividerAttribute.
   It does NOT accept Resource type. Passing $r('app.float.xxx') will cause the ArkTSCheck
   error "Argument of type 'Resource' is not assignable to parameter of type 'string | number'".
   Correct pattern: declare a string constant in AppConstants.ets and use it directly.
   Example:
     // AppConstants.ets
     export const DIVIDER_STROKE_WIDTH: string = '0.5vp';
     // Component usage
     Divider().strokeWidth(DIVIDER_STROKE_WIDTH)
   Do NOT write: .strokeWidth($r('app.float.divider_stroke_width'))
   Do NOT write: .strokeWidth("$r('app.float.divider_stroke_width')")  // literal string bug


IV. Assets & Visual Specifications
--------------------------------------------------------------------
1. Absolute Ban on Emojis:
   No emojis are allowed as UI elements or placeholders in the interface to ensure a professional look and cross-device consistency.

2. Native Icons First — Verified Whitelist:
   Only use system icons confirmed to exist in the SDK's sysResource.js
   (E:\DevEco Studio\sdk\default\openharmony\ets\build-tools\ets-loader\sysResource.js).
   Do NOT assume a sys.media name is valid; always verify before use.

   Verified available system icons (SDK 6.0.2 / API 22):
     $r('sys.media.ohos_ic_back')              — 返回箭头
     $r('sys.media.ohos_ic_public_ok')         — 勾选确认
     $r('sys.media.ohos_ic_public_clock')      — 时钟 / 历史
     $r('sys.media.ohos_ic_public_arrow_left') — 向左箭头
     $r('sys.media.ohos_ic_public_arrow_right')— 向右箭头
     $r('sys.media.ohos_ic_public_more')       — 更多（三点）
     $r('sys.media.ohos_ic_public_add')        — 新增加号
     $r('sys.media.ohos_ic_public_cancel')     — 取消
     $r('sys.media.ohos_ic_public_close')      — 关闭
     $r('sys.media.ohos_ic_public_edit')       — 编辑
     $r('sys.media.ohos_ic_public_search_filled') — 搜索
     $r('sys.media.ohos_ic_public_share')      — 分享
     $r('sys.media.ohos_ic_public_camera')     — 相机
     $r('sys.media.ohos_ic_public_scan')       — 扫码

   Known MISSING from SDK (do NOT use, use custom SVG instead):
     $r('sys.media.ohos_ic_public_home')       — 不存在，用 $r('app.media.ic_tab_home')
     $r('sys.media.ohos_ic_public_settings')   — 不存在，用 $r('app.media.ic_settings')

3. Custom SVG Vectors:
   When system icons do not meet requirements, uniformly use the SVG format to draw them
   yourself and store them in the flow/src/main/resources/base/media/ directory to ensure
   they scale without distortion across multiple screen densities.
   Reference with $r('app.media.icon_name') (without the .svg extension).
   SVG files must use viewBox="0 0 24 24" and fill="currentColor" to support fillColor tinting.

4. Decoupling Theme & Styles:
   Uniformly define Typography scales and borderless design transparency variables in ArkTS.
   It is strictly forbidden to hardcode specific color values and pixel-level borders inside
   components, facilitating future expansion for dark mode or custom background features.
   Exception: Divider.strokeWidth must use a string constant (see III.4) because the API
   does not accept Resource type.

