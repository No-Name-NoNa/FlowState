# Flow State - 沉浸式任务管理应用

基于 HarmonyOS 6.0.2 开发的情绪驱动型专注管理应用。

## 📱 应用特性

### 核心功能
- ✅ **情绪签到系统** - 根据当前心情智能推荐专注模式
- ✅ **任务管理** - 双层任务/日程结构，支持优先级设置
- ✅ **专注计时器** - 支持倒计时/正计时两种模式
- ✅ **数据记录** - 完整的专注历史和情绪趋势分析
- ✅ **主题系统** - 预设5种主题 + 支持自定义主题
- ✅ **数据持久化** - 使用 HarmonyOS Preferences API
- ⚠️ **Live Window** - 实况窗框架已实现（需配置扩展）
- ⚠️ **后台保活** - 长时任务支持（需申请权限）
- ⚠️ **AI 功能** - 预留接口，支持 DeepSeek API 集成

### 页面结构

```
Flow State
├── 首页 (HomePage)
│   ├── 心情快捷打卡
│   ├── 心情记录卡片
│   ├── 专注快捷入口
│   ├── AI 节律洞察
│   └── AI 计划制定
├── 任务页 (TaskPage)
│   ├── 任务列表
│   ├── 日程管理
│   └── 统计图表
├── 记录页 (RecordsPage)
│   ├── 时间维度切换
│   ├── 统计数据
│   ├── 情绪热力图
│   └── 专注时间轴
├── 专注页 (FocusPage)
│   ├── 倒计时/正计时
│   ├── 暂停/继续/完成
│   └── 完成复盘
├── 设置页 (SettingsPage)
│   ├── 专注偏好
│   ├── 通知设置
│   └── 主题管理
└── 登录页 (LoginPage)
    └── 弱登录设计
```

## 🏗️ 项目结构

```
flow/src/main/ets/
├── models/
│   └── DataModels.ets          # 数据模型定义
├── utils/
│   ├── Constants.ets            # 常量配置
│   ├── DataManager.ets          # 数据持久化管理
│   ├── MoodEngine.ets           # 情绪推荐引擎
│   ├── TimeFormatter.ets        # 时间格式化工具
│   ├── ThemeManager.ets         # 主题管理器
│   ├── LiveWindowManager.ets    # 实况窗管理器
│   └── BackgroundTaskUtil.ets   # 后台任务工具
├── components/
│   └── common/
│       ├── GlassCard.ets        # 毛玻璃卡片组件
│       └── LoadingIndicator.ets # 加载指示器
├── pages/
│   ├── Index.ets                # 主入口（TabBar导航）
│   ├── HomePage.ets             # 首页
│   ├── TaskPage.ets             # 任务页
│   ├── RecordsPage.ets          # 记录页
│   ├── FocusPage.ets            # 专注页
│   ├── SettingsPage.ets         # 设置页
│   └── LoginPage.ets            # 登录页
└── flowability/
    └── FlowAbility.ets          # 应用入口 Ability

flow/src/main/resources/
├── base/
│   └── element/
│       ├── color.json           # 颜色资源（浅色主题）
│       ├── string.json          # 字符串资源
│       └── float.json           # 尺寸资源
└── dark/
    └── element/
        └── color.json           # 颜色资源（深色主题）
```

## 🎨 设计规范

### 颜色系统
- **浅色主题**: 柔和的白色背景 + 蓝色主色调
- **深色主题**: 深灰色背景 + 明亮的强调色
- **避免高饱和度**: 采用自然柔和的配色
- **毛玻璃效果**: 使用 backdropBlur 实现现代化UI

### 布局规范
- 基准单位: vp (虚拟像素)
- 卡片圆角: 16vp
- 按钮圆角: 12vp
- 内边距: 4/8/16/24/32vp
- 字体大小: 12/14/16/18/24/32fp

### 组件规范
- 所有颜色使用资源引用 `$r('app.color.xxx')`
- 所有尺寸使用资源引用 `$r('app.float.xxx')`
- 所有字符串使用资源引用 `$r('app.string.xxx')`

## 📦 数据模型

### MoodEntry (情绪记录)
```typescript
{
  id: string,
  timestamp: number,
  moodValue: number (0-100),
  moodLabel: string,
  note?: string
}
```

### Task (任务)
```typescript
{
  id: string,
  title: string,
  color: string,
  priority: 'P0' | 'P1' | 'P2',
  schedules: Schedule[],
  createdAt: number
}
```

### FocusSession (专注记录)
```typescript
{
  id: string,
  scheduleId?: string,
  taskId?: string,
  startTime: number,
  endTime?: number,
  duration: number,
  mode: 'pomodoro' | 'continuous',
  completed: boolean,
  pauseCount: number,
  reflection?: string
}
```

## 🔧 配置说明

### 权限配置
在 `module.json5` 中已配置后台运行权限：
```json
"requestPermissions": [
  {
    "name": "ohos.permission.KEEP_BACKGROUND_RUNNING",
    "reason": "$string:permission_keep_background",
    "usedScene": {
      "abilities": ["FlowAbility"],
      "when": "inuse"
    }
  }
]
```

### Live Window 配置（可选）
如需启用实况窗功能，需要：
1. 创建 LiveWindowExtension.ets
2. 在 module.json5 添加 extensionAbilities 配置
3. 详见 `LiveWindowManager.ets` 注释说明

## 🚀 运行项目

### 环境要求
- HarmonyOS SDK: 6.0.2 (API 22)
- DevEco Studio: 最新版本
- Node.js: 建议 v16+

### 构建步骤
1. 使用 DevEco Studio 打开项目
2. 同步依赖: `File -> Sync and Refresh Project`
3. 编译项目: `Build -> Make Module 'flow'`
4. 运行: `Run -> Run 'flow'`

### 测试设备
- HarmonyOS 真机 (推荐)
- HarmonyOS 模拟器

## 📝 开发注意事项

### 数据持久化
- 使用 `DataManager` 统一管理数据
- 所有数据操作都是异步的 (async/await)
- 数据存储在 Preferences 中，应用卸载后清除

### 主题切换
- 通过 `ThemeManager` 管理主题
- 支持浅色/深色及自定义主题
- 主题切换后需重启应用生效（系统级配置）

### 后台任务
- 专注计时器可在后台运行
- 需要用户授予后台运行权限
- 退出应用前会保存计时状态

### Live Window
- 框架代码已实现，需要配置扩展
- 支持锁屏显示和负一屏显示
- 实际效果需在真机上测试

## 🎯 待实现功能

### V2 规划
- [ ] DeepSeek AI 集成（节律洞察 + 计划制定）
- [ ] 语音输入支持
- [ ] 白噪音播放
- [ ] 背景图片自定义
- [ ] 图片裁剪功能
- [ ] 云端数据同步
- [ ] 多设备账号登录
- [ ] 导出数据功能
- [ ] 更丰富的图表展示
- [ ] 完整的 Live Window UI

## 📄 许可证

MIT License

## 👥 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系方式

- 项目地址: [GitHub Repository]
- 问题反馈: [Issues]

---

**Flow State** - 让专注成为一种习惯 🎯
