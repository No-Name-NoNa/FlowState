# ArkTS Coding Standards

> **Project:** FlowState — HarmonyOS 6.0.2 (API Level 22)  
> **Purpose:** Authoritative reference for ArkTS syntax rules. Prevents confusion between standard TypeScript and ArkTS.  
> **Scope:** All `.ets` source files under `flow/src/main/ets/`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Type System](#2-type-system)
3. [Variable Declarations](#3-variable-declarations)
4. [Objects and Classes](#4-objects-and-classes)
5. [Functions](#5-functions)
6. [Generics](#6-generics)
7. [Enums](#7-enums)
8. [ArkTS-Exclusive Features](#8-arkts-exclusive-features)
9. [Decorators Reference](#9-decorators-reference)
10. [Import Conventions](#10-import-conventions)
11. [Naming Conventions](#11-naming-conventions)
12. [Forbidden Patterns](#12-forbidden-patterns)
13. [Common Migration Pitfalls](#13-common-migration-pitfalls)

---

## 1. Overview

**ArkTS** (Ark TypeScript) is Huawei's dedicated programming language for HarmonyOS NEXT.  
It is based on TypeScript syntax but applies significantly stricter static checks for:

- Compile-time type safety (prevents entire categories of runtime errors)
- AOT compilation performance on the ArkCompiler
- Deterministic memory layout of objects
- First-class declarative UI (ArkUI) via language-level extensions

### Relationship to TypeScript

```
JavaScript  ──→  TypeScript (adds optional static types)
                        │
                        └──→  ArkTS (mandatory strict types + UI extensions)
```

ArkTS is **not** a runtime superset of TypeScript. Code valid in TypeScript may be **rejected at compile time** in ArkTS.  
The key philosophy: **all types must be known at compile time; no runtime type or structure changes are allowed.**

---

## 2. Type System

### 2.1 No `any` or `unknown`

ArkTS forbids `any` and `unknown`. Every variable, parameter, and return value must have a concrete, resolvable type.

```typescript
// ❌ TypeScript — allowed
let value: any = fetchData();

// ✅ ArkTS — use a concrete type or interface
let value: UserData = fetchData();
```

### 2.2 Mandatory Explicit Type Annotations

Type inference is supported for simple literals, but function parameters, return types, and class properties **must always be explicitly annotated**.

```typescript
// ❌ ArkTS — missing parameter/return type annotations
function calculateTotal(price, quantity) {
  return price * quantity;
}

// ✅ ArkTS
function calculateTotal(price: number, quantity: number): number {
  return price * quantity;
}
```

### 2.3 Strict Null Checks

`null` and `undefined` are separate types. Always use optional chaining (`?.`) or explicit null checks rather than assuming a value is non-null.

```typescript
// ❌ ArkTS — potential null dereference
let userName: string = user.profile.name;

// ✅ ArkTS
let userName: string = user.profile?.name ?? 'Guest';
```

### 2.4 Type Assertions (`as`)

The `as T` syntax is supported for necessary casts, but it must be used sparingly and only where the developer has certainty. Avoid using `as` to escape type errors.

```typescript
// ⚠️  Use only when truly necessary
let inputElement = document.getElementById('myInput') as HTMLInputElement;

// ❌ Forbidden — using `as` to bypass type errors is bad practice
let count = (someValue as any).length;
```

> The angle-bracket style (`<T>value`) is **NOT supported** in ArkTS. Always use `value as T`.

### 2.5 Union and Intersection Types

Union (`|`) and intersection (`&`) types are supported with restrictions. Avoid overly complex combinations; prefer named interfaces.

```typescript
// ✅ Simple union is fine
type ButtonState = 'idle' | 'loading' | 'disabled';

// ✅ Simple intersection is fine
type NamedColor = Color & { colorName: string };

// ❌ Avoid — complex nested unions/intersections reduce clarity
type ComplexType = (A | B) & (C | D) & E;
```

### 2.6 `never` Type

`never` is supported only as a return type for functions that never return (infinite loops, always-throwing functions).

```typescript
// ✅ Correct usage
function throwError(message: string): never {
  throw new Error(message);
}
```

### 2.7 Nominal vs. Structural Typing

ArkTS moves toward **nominal typing** for custom types: two types with identical shapes are NOT automatically interchangeable unless they share the same type name or inheritance chain.

```typescript
interface PointA { x: number; y: number; }
interface PointB { x: number; y: number; }

// ❌ In strict ArkTS — PointA and PointB are not the same type
let a: PointA = { x: 1, y: 2 };
let b: PointB = a; // may cause a compile error

// ✅ Use the same interface or extend from a common base
```

---

## 3. Variable Declarations

### 3.1 Use `let` and `const`; Never `var`

`var` is **forbidden** in ArkTS. Use `let` for mutable variables and `const` for immutable references.

```typescript
// ❌ Forbidden
var itemCount = 0;

// ✅ Correct
let itemCount: number = 0;
const maxRetries: number = 3;
```

### 3.2 Always Initialize Variables

All variables must be initialized at the point of declaration or immediately in the constructor. Uninitialized variables are not allowed.

```typescript
// ❌ ArkTS — uninitialized variable
let userName: string;

// ✅ ArkTS
let userName: string = '';
```

### 3.3 `const` for Objects and Arrays

`const` prevents rebinding, not mutation. Use it for all objects and arrays that should not be reassigned.

```typescript
const taskList: string[] = [];
taskList.push('New Task');  // ✅ Mutation is fine; rebinding is not
```

---

## 4. Objects and Classes

### 4.1 No Dynamic Property Addition

The structure of an object is fixed at compile time. Adding new properties at runtime is **forbidden**.

```typescript
interface UserProfile {
  id: number;
  name: string;
}

const user: UserProfile = { id: 1, name: 'Alice' };

// ❌ Forbidden — adding a property not in the interface
(user as Record<string, unknown>)['email'] = 'alice@example.com';

// ✅ Correct — declare all properties in the interface upfront
interface UserProfile {
  id: number;
  name: string;
  email?: string;  // Optional property
}
```

### 4.2 No `delete` Operator

The `delete` operator is **not supported** in ArkTS.

```typescript
// ❌ Forbidden
delete user.email;

// ✅ Set to undefined or use optional property
user.email = undefined;
```

### 4.3 Class Property Initialization

All class properties must be initialized either at declaration or in the constructor.

```typescript
// ❌ ArkTS — property not initialized
class TaskManager {
  taskList: string[];
}

// ✅ ArkTS
class TaskManager {
  taskList: string[] = [];
}
```

### 4.4 No Prototype Modification

Modifying the prototype of built-in types or custom classes at runtime is **forbidden**.

```typescript
// ❌ Forbidden
Array.prototype.customMethod = function() { /* ... */ };
String.prototype.trim = function() { /* ... */ };
```

### 4.5 Private Class Members

Use the `private` keyword instead of the `#` ECMAScript private field syntax.

```typescript
// ❌ Not supported in ArkTS
class Counter {
  #count: number = 0;
}

// ✅ ArkTS
class Counter {
  private count: number = 0;
}
```

### 4.6 Static Initializer Blocks

A class may have **at most one** static initializer block.

```typescript
// ❌ Forbidden — multiple static blocks
class Config {
  static { this.init(); }
  static { this.setup(); }  // Error!
}

// ✅ Correct
class Config {
  static {
    this.init();
    this.setup();
  }
}
```

---

## 5. Functions

### 5.1 Explicit Return Types

All functions and methods must declare their return type explicitly.

```typescript
// ❌ Missing return type
function fetchUserName(userId: number) {
  return `user_${userId}`;
}

// ✅ Correct
function fetchUserName(userId: number): string {
  return `user_${userId}`;
}
```

### 5.2 No `eval()`

The `eval()` function is **not supported** in ArkTS. Code must be statically analyzable at compile time.

```typescript
// ❌ Forbidden
const result = eval('2 + 2');
```

### 5.3 Arrow Functions

Arrow functions are fully supported and are the preferred way to pass callbacks.

```typescript
const filteredItems = itemList.filter((item: string): boolean => item.length > 0);
```

### 5.4 Optional and Default Parameters

Both optional (`?`) and default parameters are supported.

```typescript
function createTask(title: string, priority: number = 1, dueDate?: string): void {
  // implementation
}
```

### 5.5 Rest Parameters

Rest parameters are supported but must be typed as an array.

```typescript
function logMessages(...messages: string[]): void {
  messages.forEach((message: string) => console.log(message));
}
```

### 5.6 No `Function` Type

Do not use the generic `Function` type. Always specify the complete function signature.

```typescript
// ❌ Too generic
let callback: Function;

// ✅ Explicit signature
let callback: (event: ClickEvent) => void;
```

---

## 6. Generics

Generics are supported with the following restrictions:

### 6.1 Supported

```typescript
// ✅ Generic class
class Repository<T> {
  private items: T[] = [];

  add(item: T): void {
    this.items.push(item);
  }

  getAll(): T[] {
    return this.items;
  }
}

// ✅ Generic function
function getFirstItem<T>(items: T[]): T | undefined {
  return items.length > 0 ? items[0] : undefined;
}
```

### 6.2 Not Supported

```typescript
// ❌ Conditional types — not supported
type IsArray<T> = T extends Array<infer U> ? U : never;

// ❌ Mapped types — not supported
type ReadonlyUser = { readonly [K in keyof User]: User[K] };

// ❌ TypeScript utility types (Partial, Required, Pick, Omit, etc.) — not available
type PartialUser = Partial<User>;

// ❌ Template literal types — not supported
type EventName = `on${string}`;
```

---

## 7. Enums

### 7.1 Basic String and Numeric Enums

```typescript
// ✅ Numeric enum
enum TaskStatus {
  Pending = 0,
  InProgress = 1,
  Completed = 2,
  Cancelled = 3
}

// ✅ String enum
enum LogLevel {
  Debug = 'DEBUG',
  Info = 'INFO',
  Warn = 'WARN',
  Error = 'ERROR'
}
```

### 7.2 No Computed or Mixed Members

Enum members must have constant values. Computed values and mixed enums (some string, some number) are **not supported**.

```typescript
// ❌ Computed enum member — forbidden
enum Flags {
  Read = 1 << 0,   // computed — not allowed
  Write = 1 << 1,
}

// ❌ Mixed enum — forbidden
enum MixedEnum {
  A = 1,
  B = 'two',
}
```

---

## 8. ArkTS-Exclusive Features

These features exist only in ArkTS and have no equivalent in standard TypeScript.

### 8.1 The `struct` Keyword

UI components are declared with `struct`, not `class`. A struct cannot extend other structs and cannot implement interfaces.

```typescript
// ✅ ArkTS UI component
@Component
struct TaskCard {
  @Prop taskTitle: string = '';

  build() {
    Text(this.taskTitle)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
  }
}
```

### 8.2 The `build()` Method

Every `@Component` struct **must** implement a `build()` method that describes its UI tree. The `build()` method:

- Must contain exactly one root UI element
- Cannot contain variable declarations, conditionals outside of `if`, or loops outside of `ForEach`/`LazyForEach`
- Must not call non-UI functions directly (use `@Builder` for extracted UI blocks)

```typescript
@Component
struct StatusBadge {
  @Prop status: string = '';

  build() {
    // ✅ Single root element
    Row() {
      Text(this.status)
        .fontSize(12)
        .fontColor(Color.White)
    }
    .backgroundColor(Color.Blue)
    .padding(4)
  }
}
```

### 8.3 ArkUI Declarative DSL

ArkTS extends the language with a chainable attribute DSL for ArkUI components. Attributes are chained with `.` after the component call — this is NOT method chaining in the normal OOP sense.

```typescript
Text('Hello, FlowState')
  .fontSize($r('app.float.page_text_font_size'))
  .fontWeight(FontWeight.Bold)
  .fontColor(Color.Black)
  .textAlign(TextAlign.Center)
  .onClick(() => {
    this.message = 'Clicked!';
  })
```

### 8.4 Resource References

Use `$r()` for referencing app resources instead of hardcoded values.

```typescript
// ❌ Hardcoded — avoid for maintainability
Text('My App').fontSize(24)

// ✅ Resource reference
Text($r('app.string.app_name')).fontSize($r('app.float.title_font_size'))
```

---

## 9. Decorators Reference

All state management and component decorators are **ArkTS-only**. They have no TypeScript equivalent.

### 9.1 Component Lifecycle Decorators

| Decorator | Target | Description |
|---|---|---|
| `@Component` | `struct` | Marks a struct as a reusable UI component |
| `@Entry` | `struct` | Marks a component as the entry point of a page |
| `@Preview` | `struct` | Marks a component for DevEco Studio live preview |
| `@Reusable` | `struct` | Marks a component as eligible for node reuse (performance) |
| `@CustomDialog` | `struct` | Marks a struct as a custom dialog controller |

```typescript
@Entry
@Component
struct HomePage {
  build() {
    Column() {
      Text('Home')
    }
  }
}
```

### 9.2 State Management Decorators

| Decorator | Scope | Mutable by | Description |
|---|---|---|---|
| `@State` | Component | Self only | Local reactive state; triggers re-render on change |
| `@Prop` | Component | Parent → Child (one-way) | Value passed from parent; child can read but parent owns it |
| `@Link` | Component | Parent ↔ Child (two-way) | Bidirectional binding with parent's `@State` |
| `@Provide` | Ancestor | Ancestor | Exposes a value to all descendant components |
| `@Consume` | Descendant | — | Consumes a value exposed by an ancestor's `@Provide` |
| `@ObjectLink` | Component | — | Used with `@Observed` classes for nested object reactivity |
| `@Observed` | Class | — | Marks a class for deep observation (used with `@ObjectLink`) |
| `@Watch` | Property | — | Calls a callback when the decorated property changes |

```typescript
@Observed
class TaskItem {
  taskName: string = '';
  isDone: boolean = false;
}

@Component
struct TaskList {
  @State taskItems: TaskItem[] = [];
  @State filterText: string = '';
  @Watch('onFilterChange') @State activeFilter: string = 'all';

  onFilterChange(filterName: string): void {
    // Called whenever activeFilter changes
    console.log(`Filter changed to: ${filterName}`);
  }

  build() {
    Column() {
      ForEach(this.taskItems, (item: TaskItem) => {
        TaskRow({ taskItem: item })
      })
    }
  }
}

@Component
struct TaskRow {
  @ObjectLink taskItem: TaskItem;

  build() {
    Text(this.taskItem.taskName)
  }
}
```

### 9.3 Builder and Style Decorators

| Decorator | Description |
|---|---|
| `@Builder` | Extracts a reusable UI block as a method or standalone function |
| `@BuilderParam` | Declares a slot in a component that accepts an `@Builder` function |
| `@Styles` | Extracts repeated attribute chains into a named style function |
| `@Extend(Component)` | Extends a built-in component with custom attributes |
| `@AnimatableExtend` | Extends an animatable attribute on a built-in component |

```typescript
// @Builder — standalone builder function
@Builder
function primaryButton(label: string, onClick: () => void): void {
  Button(label)
    .onClick(onClick)
    .backgroundColor(Color.Blue)
    .fontColor(Color.White)
    .borderRadius(8)
}

// @Builder — component method builder
@Component
struct TaskCard {
  @BuilderParam cardFooter: () => void;  // Slot

  @Builder defaultFooter(): void {
    Text('No footer provided')
  }

  build() {
    Column() {
      Text('Task Title')
      this.cardFooter !== undefined ? this.cardFooter() : this.defaultFooter()
    }
  }
}

// @Styles — reusable style block
@Styles
function containerStyle(): void {
  .width('100%')
  .padding(16)
  .backgroundColor(Color.White)
  .borderRadius(12)
}

// @Extend — extending a built-in component
@Extend(Text)
function titleText(): AttributeModifier<TextAttribute> {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .fontColor($r('app.color.text_primary'))
}
```

---

## 10. Import Conventions

### 10.1 HarmonyOS Kit Imports

Use the `@kit.*` namespace for HarmonyOS SDK modules. Never import from internal paths directly.

```typescript
// ✅ Kit imports
import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
```

### 10.2 Named Imports Over Default Imports

Prefer named imports for better tree-shaking and type clarity. Only use default imports when the module requires it.

```typescript
// ✅ Named import
import { hilog } from '@kit.PerformanceAnalysisKit';

// ✅ Default import (for native NAPI modules)
import testNapi from 'libflow.so';
```

### 10.3 No Wildcard Imports

Avoid `import *` as it bypasses tree-shaking and can mask unused dependencies.

```typescript
// ❌ Avoid
import * as ArkUI from '@kit.ArkUI';

// ✅ Import only what you need
import { window, display } from '@kit.ArkUI';
```

---

## 11. Naming Conventions

All identifiers in ArkTS source files follow these conventions.

### 11.1 Variables and Parameters — `camelCase`

```typescript
let taskCount: number = 0;
let isLoading: boolean = false;
const maxRetryCount: number = 3;

function loadUserData(userId: string, includeProfile: boolean): void { /* ... */ }
```

### 11.2 Functions and Methods — `camelCase`

```typescript
function calculateProgress(completedTasks: number, totalTasks: number): number {
  return (completedTasks / totalTasks) * 100;
}

class TaskService {
  fetchAllTasks(): Promise<Task[]> { /* ... */ }
  createNewTask(title: string): Task { /* ... */ }
  deleteTaskById(taskId: string): void { /* ... */ }
}
```

### 11.3 Classes, Structs, Interfaces, and Enums — `PascalCase`

```typescript
class TaskRepository { /* ... */ }
struct HomePageView { /* ... */ }
interface UserProfile { /* ... */ }
enum FilterMode { All, Active, Completed }
```

### 11.4 Constants — `UPPER_SNAKE_CASE`

Use `UPPER_SNAKE_CASE` only for module-level constants that represent fixed configuration values.

```typescript
const DOMAIN: number = 0x0000;
const MAX_TASK_TITLE_LENGTH: number = 100;
const DEFAULT_PAGE_SIZE: number = 20;
```

### 11.5 Files — `PascalCase.ets`

ArkTS source files use `PascalCase` matching their primary export:

```
FlowAbility.ets          → exports class FlowAbility
FlowBackupAbility.ets    → exports class FlowBackupAbility
Index.ets                → the entry page (special case)
TaskListPage.ets         → exports struct TaskListPage
TaskCard.ets             → exports struct TaskCard
```

### 11.6 Decorators — Use Exactly as Specified

Decorator names are fixed by the ArkTS framework. Do not abbreviate or alias them.

```typescript
// ✅ Correct decorator names
@Entry
@Component
@State
@Prop
@Link
@Builder
@Styles
```

---

## 12. Forbidden Patterns

Quick reference for TypeScript patterns that are **not valid** in ArkTS.

| Pattern | TypeScript | ArkTS |
|---|---|---|
| Dynamic type | `let x: any = ...` | ❌ Forbidden — use concrete type |
| Unknown type | `let x: unknown = ...` | ❌ Forbidden |
| `var` keyword | `var count = 0` | ❌ Use `let` or `const` |
| Runtime property add | `obj.newKey = value` | ❌ Forbidden — define in interface |
| `delete` operator | `delete obj.prop` | ❌ Forbidden — set to `undefined` |
| Prototype mutation | `Array.prototype.x = ...` | ❌ Forbidden |
| `eval()` | `eval('code')` | ❌ Forbidden |
| Private `#` fields | `#count = 0` | ❌ Use `private count` |
| Angle-bracket cast | `<T>value` | ❌ Use `value as T` |
| Conditional types | `T extends U ? X : Y` | ❌ Not supported |
| Mapped types | `{ [K in keyof T]: ... }` | ❌ Not supported |
| TypeScript utility types | `Partial<T>`, `Pick<T>` | ❌ Not available |
| Template literal types | `` `on${string}` `` | ❌ Not supported |
| Computed enum members | `A = 1 << 0` | ❌ Constant values only |
| Generic `Function` type | `let f: Function` | ❌ Use explicit signature |
| Wildcard imports | `import * as X` | ❌ Avoid |
| Multiple static blocks | Two `static { }` in class | ❌ One only |
| JSX syntax | `<MyComponent />` | ❌ Not applicable; use ArkUI DSL |

---

## 13. Common Migration Pitfalls

Side-by-side comparisons for developers migrating from TypeScript to ArkTS.

### 13.1 Typing API Responses

```typescript
// ❌ TypeScript habit — using any for API data
async function loadConfig(): Promise<any> {
  const response = await fetch('/config');
  return response.json();
}

// ✅ ArkTS — define the shape explicitly
interface AppConfig {
  theme: string;
  language: string;
  maxItems: number;
}

async function loadConfig(): Promise<AppConfig> {
  const response = await fetch('/config');
  return response.json() as AppConfig;
}
```

### 13.2 Iterating Object Properties

```typescript
// ❌ TypeScript — dynamic key access
for (const key in userObj) {
  console.log(userObj[key]);  // May not compile in ArkTS
}

// ✅ ArkTS — iterate over a known array or use typed entries
const userEntries: [string, string][] = [
  ['name', userObj.name],
  ['email', userObj.email],
];
for (const [key, value] of userEntries) {
  console.log(`${key}: ${value}`);
}
```

### 13.3 Optional Chaining and Nullish Coalescing

```typescript
// ❌ TypeScript-style null check (verbose)
const title = task !== null && task !== undefined ? task.title : 'Untitled';

// ✅ ArkTS — use optional chaining and nullish coalescing
const title: string = task?.title ?? 'Untitled';
```

### 13.4 Extracting UI Logic into Builders

```typescript
// ❌ Trying to return UI from a regular method (not valid in build())
@Component
struct TaskPage {
  renderEmptyState(): Column {  // Regular method — can't be called inside build()
    return Column() { Text('No tasks') };
  }
}

// ✅ ArkTS — use @Builder for extractable UI blocks
@Component
struct TaskPage {
  @Builder
  emptyStateView(): void {
    Column() {
      Image($r('app.media.empty_icon')).width(80).height(80)
      Text('No tasks yet').fontSize(16).fontColor(Color.Gray)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      if (this.taskList.length === 0) {
        this.emptyStateView()
      }
    }
  }
}
```

### 13.5 Class vs. Struct for Components

```typescript
// ❌ Using class for a UI component
@Component
class MyButton {  // Error: UI components must use struct
  build() { /* ... */ }
}

// ✅ Always use struct for UI components
@Component
struct MyButton {
  @Prop label: string = '';
  @Prop onClick: () => void = () => {};

  build() {
    Button(this.label)
      .onClick(this.onClick)
  }
}
```

### 13.6 Logging with `hilog`

```typescript
// ❌ Plain console.log (not recommended in production HarmonyOS code)
console.log('Task loaded');

// ✅ Use hilog from PerformanceAnalysisKit
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const LOG_TAG: string = 'FlowState';

hilog.info(DOMAIN, LOG_TAG, 'Task loaded: %{public}s', taskId);
hilog.error(DOMAIN, LOG_TAG, 'Failed to load: %{public}s', JSON.stringify(error));
```

---

*Last updated: 2026-05-21 | HarmonyOS SDK 6.0.2 (API Level 22)*
