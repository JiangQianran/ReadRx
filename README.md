# ReadRx 读药助手

拍一张药盒或说明书，AI 帮你读出药品的**有效期、用法用量、副作用**，用大白话讲清楚并**语音朗读**；还能查**药物 / 食物相克**、设置**每天吃药提醒**。为老年人设计：大字体、大按钮、能朗读。

```
ReadRx/
├── app/      Flutter 手机 App（安卓 / iOS）
└── server/   Node.js 后端（调用 DeepSeek）
```

## 功能

| 功能 | 说明 |
|---|---|
| 拍照识药 | 相机拍照或相册选图，同一种药可传 1～6 张（正面、有效期、说明书） |
| AI 识别 | 后端把照片交给 DeepSeek Flash 识图，按固定 JSON 返回 |
| 结果呈现 | 药名、有效期（红 = 已过期 / 橙 = 90 天内到期 / 绿 = 正常）、用法用量、副作用、禁忌、简化说明书 |
| 手动修改 | AI 认错了可以点右上角 ✎ 改药名、有效期、用量 |
| 语音朗读 | 用手机自带的中文语音朗读重点；设置里可调语速、开启「识别后自动朗读」 |
| 我的药箱 | 保存识别过的药，过期和快过期的排在最前面 |
| 相克查询 | 选药箱里的药 + 输入其他药 / 食物，AI 判断「禁止 / 慎用 / 无明显风险 / 不确定」；只选一种药时，告诉你它不能和什么一起吃 |
| 用药提醒 | 每天定时通知，根据「每日 N 次」自动推荐时间，不联网也会响 |
| 适老设置 | 字体四档可调（标准 / 大 / 特大 / 超大） |

---

## 一、启动后端（server）

需要先装 [Node.js](https://nodejs.org/) LTS 版（20 或以上）。

```powershell
cd server
npm install
copy .env.example .env      # 然后用记事本打开 .env，填入 DEEPSEEK_API_KEY
npm start
```

- DeepSeek API Key 在 <https://platform.deepseek.com> 申请并充值。
- **还没有 Key 也能先跑**：不填 Key 会自动进入「演示模式」，返回示例数据，方便先把 App 跑通。
- 启动后窗口里会显示 `http://192.168.x.x:3000` 这样的地址，**把它填到 App 的「设置 → 服务器地址」**。手机和电脑要连同一个 Wi-Fi。
- 如果手机连不上：Windows 防火墙第一次会弹窗，请点「允许访问」；或在防火墙里放行 3000 端口。

`.env` 里的配置：

| 配置 | 说明 |
|---|---|
| `DEEPSEEK_API_KEY` | 你的 Key |
| `DEEPSEEK_VISION_MODEL` | 识图模型，默认 `deepseek-flash` |
| `DEEPSEEK_TEXT_MODEL` | 相克查询模型，默认 `deepseek-flash`，想更严谨可换 `deepseek-v4-pro` |
| `APP_TOKEN` | 可选访问口令，设置后 App 里也要填相同口令，防止别人盗用接口 |
| `MOCK` | 设为 `1` 强制演示模式 |

### 接口

| 接口 | 说明 |
|---|---|
| `GET /api/health` | 测试连接 |
| `POST /api/parse` | `{ "images": ["data:image/jpeg;base64,..."] }` → 药品信息 |
| `POST /api/interaction` | `{ "drugs": ["头孢"], "foods": ["酒"] }` → 相克结果 |

提示词在 `server/src/prompts.js`，想调整 AI 的回答风格改这里即可。

---

## 二、运行 App（app）

### 方式 A：直接安装 APK（不用装 Flutter）

如果文件夹里有 `ReadRx.apk`，发到安卓手机上直接安装（需允许「安装未知来源应用」）。打开后进「设置」填服务器地址，点「保存并测试连接」。

### 方式 B：装好 Flutter 后自己编译

```powershell
cd app
flutter pub get
flutter run              # 手机连电脑并打开 USB 调试
flutter build apk        # 打包安装包，输出在 build\app\outputs\flutter-apk\app-release.apk
```

国内网络建议先设置环境变量：

```
PUB_HOSTED_URL=https://pub.flutter-io.cn
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### App 代码结构

```
app/lib/
├── main.dart                  入口：初始化语音、通知，全局字体缩放
├── app_state.dart             全局状态：设置、药箱、提醒（保存在手机本地）
├── models.dart                数据模型：Medicine / Reminder / InteractionResult
├── theme.dart                 适老化主题（大字号、大按钮）
├── services/
│   ├── api.dart               调用后端
│   ├── tts.dart               语音朗读
│   ├── notifications.dart     用药提醒（本地定时通知）
│   └── expiry.dart            有效期状态判断
├── widgets/common.dart        公共组件：卡片、有效期徽章、朗读按钮等
└── pages/
    ├── home_page.dart         底部四个标签：识药 / 药箱 / 相克 / 提醒
    ├── scan_page.dart         拍照识药
    ├── medicine_detail_page.dart  识别结果 / 药品详情
    ├── medicine_edit_page.dart    手动修改
    ├── cabinet_page.dart      我的药箱
    ├── interaction_page.dart  相克查询
    ├── reminders_page.dart    提醒列表
    ├── reminder_edit_page.dart    添加 / 修改提醒
    └── settings_page.dart     设置
```

---

## 常见问题

**提醒不响？** 国产安卓手机会杀后台。到手机「设置 → 应用 → ReadRx」：允许通知、允许自启动、电池设为「不限制」。App 的「提醒」页可以发测试通知。

**朗读没声音？** 检查手机是否有中文语音引擎（设置 → 无障碍 / 辅助功能 → 文字转语音），音量是否打开。

**识别不准？** 靠近拍、光线亮、对焦清楚；有效期常印在盒子侧面或底部，单独拍一张。识别错了可以手动改。

**连不上服务器？** 确认后端已启动、地址填的是电脑的局域网 IP（不是 localhost）、手机电脑同一 Wi-Fi、防火墙已放行。

---

> ⚠️ 本 App 的内容由 AI 生成，仅供参考，不能代替医生和药师的意见。
