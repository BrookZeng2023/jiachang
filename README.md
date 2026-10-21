# 家常 · Jiachang

A warm, bilingual iOS cookbook for everyday life, powered by [Mealie](https://github.com/mealie-recipes/mealie).

一个有生活感的中英双语 iOS 私人菜谱本：照片优先、原生 SwiftUI、数据由成熟的 Mealie 后端管理。

<p align="center">
  <img src="docs/screenshots/home-zh.jpg" width="320" alt="家常中文首页">
  &nbsp;&nbsp;
  <img src="docs/screenshots/cookbook-en.jpg" width="320" alt="Jiachang English cookbook">
</p>

## Features · 功能

- Native SwiftUI app for iOS 18+
- In-app **中文 / English** switching
- Photo-first home, cookbook, recipe detail and editor screens
- Secure credential storage in the iOS Keychain
- Mealie REST integration: sign-in, list, view, create, edit, delete and image upload
- 16 bilingual starter recipes suited to everyday life in the UK
- 16 cohesive food photographs generated for the starter set
- Reproducible app icon and seed-data tooling

---

- iOS 18+ 原生 SwiftUI
- 应用内即时切换中文 / English
- 照片优先的首页、菜谱库、详情与编辑体验
- 密码存入 iOS Keychain
- 完整对接 Mealie：登录、列表、详情、增删改和图片上传
- 附带 16 道适合英国生活的中西家常菜
- 起始菜谱配有统一风格的生活摄影图

## Architecture · 架构

The app follows a small-file, layered object model:

```text
app/jiachang/
├── Domain/          # Pure models and protocols
├── Application/     # Session and recipe-library use cases
├── Adapters/        # Mealie HTTP/DTO/repository + Keychain storage
└── Interfaces/      # SwiftUI design system, localization and features
```

UI code depends on application objects; application code depends on domain protocols; infrastructure stays in adapters. Tests cover only key contracts and failure paths.

## Requirements · 环境

- macOS with Xcode 16 or newer
- iOS 18+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- A reachable Mealie v3 server and user account

```bash
brew install xcodegen
```

## Build · 构建

```bash
git clone https://github.com/BrookZeng2023/jiachang.git
cd jiachang/app
xcodegen generate
open jiachang.xcodeproj
```

Choose your Apple Development Team in Xcode before installing on a physical device. For simulator tests:

```bash
cd app
IOS_DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro' ./scripts/check.sh
```

Change the simulator name to one installed on your Mac.

## Connect to Mealie · 连接 Mealie

Launch the app and enter:

1. The Mealie URL, for example `http://192.168.1.20:9000`
2. Your Mealie username
3. Your Mealie password

For plain HTTP on a home network, the current project permits arbitrary transport. For an internet-facing deployment, put Mealie behind HTTPS and tighten the App Transport Security policy.

## Starter recipes · 起始菜谱

The starter dataset uses a portable `中文 · English` convention, so it remains readable in Mealie's web UI while the app shows only the selected language.

Import it idempotently:

```bash
cd seed
python3 import_recipes.py \
  --server http://localhost:9000 \
  --username your-user \
  --update
```

The importer reads `MEALIE_PASSWORD` or prompts without echoing. Images are uploaded automatically from `seed/images/`.

## Quality gate · 质量闸门

```bash
cd app
./scripts/check.sh
```

The lean gate regenerates the Xcode project, builds the app and runs five focused tests covering:

- tolerant Mealie DTO decoding
- bilingual content selection
- recipe-draft normalization
- authentication failure mapping
- server failure mapping

## Repository layout

```text
app/                 iOS source, XcodeGen spec and tests
seed/                bilingual recipes, generated photos and import tools
docs/screenshots/    public screenshots
DESIGN.md             visual and engineering rationale
```

## Privacy · 隐私

Jiachang has no analytics or advertising SDK. Recipe data stays on the Mealie server you configure. The server address and username use app preferences; the password is stored in Keychain.

## License

MIT — see [LICENSE](LICENSE).
