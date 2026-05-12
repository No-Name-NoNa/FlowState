# ArkTS / HarmonyOS Official Context

Use these official Huawei sources before making ArkTS, ArkUI, or HarmonyOS architectural changes in this project.

## Primary Official Entry Points

- HarmonyOS application knowledge map: https://developer.huawei.com/consumer/cn/app/knowledge-map/
- HarmonyOS technical resources overview: https://developer.huawei.com/consumer/cn/hmos/overview/
- ArkUI overview: https://developer.huawei.com/consumer/cn/arkui/
- ArkTS overview: https://developer.huawei.com/consumer/en/arkts/
- Stage model overview: https://developer.huawei.com/consumer/cn/arkui/arkui-stage/

## Topics To Check For This App

- ArkTS language and TypeScript adaptation: use the knowledge map section "ArkTS语言".
- ArkUI UI framework: use "UI框架", especially Navigation, list layout, immersive pages, and custom dialogs.
- Stage model and UIAbility lifecycle: use "程序框架" and "Stage模型开发概述".
- Lightweight persistence: use "本地数据和文件" -> "轻量级数据持久化".
- HTTP/network features: use "系统开发" -> "HTTP数据请求".
- Live Window: use "应用服务开发" -> "实况窗服务" before implementing or changing `LiveWindowManager`.
- Performance and layout quality: use "应用质量" -> "合理使用布局" and "状态管理最佳实践".

## Project-Specific Rules For AI Changes

- Do not invent ArkTS or ArkUI APIs. If a component, modifier, decorator, or system kit is not confirmed in official docs or already compiling in this repo, avoid it.
- Prefer APIs already used in this repo unless official docs justify a new one.
- After edits, run:

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp
```

- Treat `BUILD SUCCESSFUL` as required before claiming the app still compiles.
- Existing warnings about deprecated `router.pushUrl/back/getState`, `@Entry export struct`, and missing signing config are known project warnings unless the current task specifically addresses them.
