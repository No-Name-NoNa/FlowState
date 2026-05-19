# 流序交付总结

Updated: 2026-05-19

流序是一款 HarmonyOS 时间线计划应用。当前交付版本围绕“收集、安排、专注、复盘”形成完整闭环，并以 `今天` 作为默认主页面。

## 交付内容

- ArkTS/ArkUI 应用源码。
- Today、Inbox、Plan、Future、Focus、Review、Settings 七个核心页面。
- 本地数据模型、迁移逻辑和主题管理。
- 用户手册、快速指南、功能总表和发布交付说明。
- 应用图标与产品名称：流序。

## 核心能力

- 快速收集想法和待办。
- 将任务安排到今天、明天或指定日期。
- 使用时间线查看今日安排。
- 进入专注计时并记录完成结果。
- 复盘今日和本周节奏。
- 管理专注时长、每日容量、提醒偏好和主题外观。

## 构建

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

构建产物：

- `flow/build/default/outputs/default/app/flow-default.hap`
- `flow/build/default/outputs/default/flow-default-unsigned.hap`

## 文档入口

- `README.md`
- `docs/USER_GUIDE.md`
- `docs/USER_MANUAL.md`
- `docs/MASTER_FEATURE_CHECKLIST.md`
- `docs/FUNCTION_MODULE_SPEC.md`
- `docs/RELEASE_HANDOFF.md`

## 后续方向

后续迭代以精修为主：

1. 继续提升卡片、按钮、排版和主题质感。
2. 清理任何生硬或开发态文案。
3. 保持操作路径短，不增加复杂流程。
4. 新功能优先从 `docs/MASTER_FEATURE_CHECKLIST.md` 选择。
