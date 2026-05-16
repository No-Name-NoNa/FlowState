# Flow State Release Handoff

Updated: 2026-05-16

This document records the current handoff state for the HarmonyOS Flow State app. It is intentionally factual: the static implementation is buildable, while true release readiness still depends on device runtime QA, release signing, and official system capability verification.

## Current Build State

- Branch: `ksy`
- Static implementation checkpoint: complete for the current first-experience scope.
- Product estimate in `docs/MASTER_FEATURE_CHECKLIST.md`: about 99%.
- Latest known build output:
  - `flow/build/default/outputs/default/app/flow-default.hap`
  - `flow/build/default/outputs/default/flow-default-unsigned.hap`
- Known build warnings:
  - Obfuscation is not configured.
  - Release signing is not configured in `build-profile.json5`.

## Build Command

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\hvigor\bin\hvigor.js' assembleApp --no-daemon
```

## Device Check

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' list targets -v
```

Current result in this workspace: empty output, so no HarmonyOS phone or emulator target is available.

## Install Step Once Device Is Available

Use the HAP generated under `flow/build/default/outputs/default/app/`.

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' install 'D:\FlowState\flow\build\default\outputs\default\app\flow-default.hap'
```

If installation fails, first confirm that `hdc list targets -v` returns a device and then check DevEco signing/profile requirements.

## What Is Ready

- Today-first operating loop.
- Inbox capture and scheduling.
- Plan source panel, auto-plan suggestions, and future-to-today fallback.
- Future grouped schedule ownership.
- Focus start, completion, reflection, and next-block handoff.
- Review today/week narrative, weekly rhythm, and empty-state guide.
- Settings mainline, local data status, capability status, and experience status.
- Local data migration and startup readiness guard.
- Device QA checklist.
- User manual and quick-start guide.

## What Is Not Claimed

- Real system reminder delivery is not implemented.
- Release signing is not configured.
- Runtime route stack, keyboard, picker height, sheet behavior, and small-screen fit are not device-verified.
- Calendar, widget, background/live focus state, import/export, project/tag management, and natural-language parsing remain future modules.

## Final Acceptance Boundary

The app should only be called release-ready after:

1. `hdc list targets -v` shows a real HarmonyOS phone or emulator.
2. The HAP installs and launches.
3. `docs/DEVICE_QA_CHECKLIST.md` is completed end to end.
4. Any device-found UI or route defects are fixed.
5. Release signing is configured.
6. Reminder/system capability claims are either implemented from official documentation or kept visibly disabled/honest.

## Official Documentation Context

- HarmonyOS application development guide: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide
- HarmonyOS API reference entry: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/development-intro-api
- ArkUI portal: https://developer.huawei.com/consumer/cn/arkui/
