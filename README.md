# 家常 · Jiachang

A warm, bilingual iOS cookbook for everyday life. Open it and cook — no account, no server.

一个有生活感的中英双语 iOS 私人菜谱本：打开就能用，不用登录，也不需要服务器。

<p align="center">
  <img src="docs/screenshots/home-zh.jpg" width="320" alt="家常中文首页">
  &nbsp;&nbsp;
  <img src="docs/screenshots/cookbook-en.jpg" width="320" alt="Jiachang English cookbook">
</p>

## Features · 功能

- Native SwiftUI app for iOS 18+
- Works offline out of the box: 16 bilingual starter recipes and photos ship inside the app
- In-app **中文 / English** switching
- Photo-first home, cookbook, recipe detail and editor screens
- Add, edit and delete any recipe, including the starter set; changes stay on the device
- Take a recipe photo or choose one with the system photo picker; camera access is requested only when you choose to take a photo
- About Jiachang includes a message from Brook, privacy and data-storage notes, permission explanations, food-safety guidance and licensing information
- New starter recipes arrive with each app release

---

- iOS 18+ 原生 SwiftUI
- 开箱即用：16 道中英双语家常菜和配图随 app 内置
- 应用内即时切换中文 / English
- 照片优先的首页、菜谱库、详情与编辑体验
- 任何菜谱都能新增、编辑、删除（包括内置菜谱），数据只存在这台手机上
- 新的内置菜谱随版本更新送达

## How updates work · 发版更新规则

Built-in recipes live in `app/jiachang/Resources/Catalog/`. Each release ships the latest catalog; the user's own changes are layered on top and always win:

| User action | After the next release |
|---|---|
| Nothing | Shows the new catalog version |
| Edited a built-in recipe | Keeps the user's version; **Restore original** in the recipe menu brings back the latest catalog version |
| Deleted a built-in recipe | Stays deleted; **Settings → Restore deleted starter recipes** brings it back |
| Added a personal recipe | Kept as is |
| — | Recipes newly added to the catalog appear automatically |

内置菜谱一律按 `id` 识别：改过的保留用户版本，删掉的不会复活，新增的自动出现。

### Adding or changing a built-in recipe · 维护内置菜谱

1. Edit `app/jiachang/Resources/Catalog/recipes.json`. Every recipe needs a unique, **never-changing** `id` (generate one with `uuidgen`) and a `key`.
2. Put its photo at `app/jiachang/Resources/Catalog/images/<key>.jpg`.
3. Bump `CFBundleShortVersionString` in `app/project.yml`, run the quality gate, and ship.

Text uses the portable `中文 · English` convention; the app shows only the selected side. Recipes without the delimiter display unchanged in either language.

## Architecture · 架构

The app follows a small-file, layered object model:

```text
app/jiachang/
├── Domain/          # Pure models and the repository protocol
├── Application/     # Recipe-library and language use cases
├── Adapters/        # Bundled catalog + on-device overlay storage
├── Interfaces/      # SwiftUI design system, localization and features
└── Resources/Catalog/  # Built-in recipes.json and photos
```

UI code depends on application objects; application code depends on domain protocols; storage stays in adapters. Tests cover only key contracts and failure paths.

## Requirements · 环境

- macOS with Xcode 16 or newer
- iOS 18+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

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

Choose your Apple Development Team in Xcode before installing on a physical device.

## Quality gate · 质量闸门

```bash
cd app
IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/check.sh
```

Change the simulator name to one installed on your Mac. The gate regenerates the Xcode project, builds the app and runs focused tests covering:

- the shipped catalog decodes, has unique ids and a photo for every recipe
- user edits, deletions and photos survive a catalog update; restore works
- an unreadable library file is set aside instead of overwritten
- bilingual content selection
- recipe-draft normalization

## Release to TestFlight · 发布到 TestFlight

Uploads use Xcode's own tools; no third-party release tooling is required.

One-time setup:

1. In App Store Connect, create the app record with bundle id `io.github.BrookZeng2023.jiachang`.
2. Sign into Xcode → Settings → Accounts with the Apple account that owns the team. `RELEASE_AUTH=xcode` is the default and was verified for this app's first upload.
3. Copy `app/scripts/release.env.example` to `app/release.local.env` (gitignored) and fill in the team id. For API authentication, explicitly select `RELEASE_AUTH=api` and supply the key id, issuer id and key path. An App Manager key alone may lack cloud-signing permission; API mode needs a suitable distribution signing setup.
4. For internal testing, testers must be eligible App Store Connect users with app access; adding an arbitrary Apple ID is not enough. Enable automatic distribution on that internal group. For friends who should not have account access, use an external group instead; beta review and test information may be required before distribution.

Store the `.p8` private key only in the mounted, unlocked PrivateVault, never in the repository or its encrypted backing directory. `release.local.env` contains identifiers and a path, not the key itself. This script uploads a build; it does not create the App Store Connect record, manage testers or submit external beta review.

Then, from a clean working tree:

```bash
cd app
scripts/release.sh            # runs the quality gate, archives, uploads
scripts/release.sh --skip-tests
```

The build number is the git commit count, so each commit yields a higher `CFBundleVersion`. The script refuses to run with uncommitted changes, verifies the archived version, build and bundle id before uploading, and tags the commit `build/<version>-<build>` after a successful upload. Archives and logs are written outside the repo (`~/Brook/Local/jiachang/releases/` by default).

Bump `CFBundleShortVersionString` in `app/project.yml` for a new user-facing version.

## Repository layout

```text
app/                 iOS source, built-in catalog, XcodeGen spec, scripts and tests
app/scripts/         quality gate, TestFlight release, icon and photo tooling
docs/screenshots/    public screenshots
DESIGN.md            visual and engineering rationale
```

## Privacy · 隐私

Jiachang has no account, no network access, and no analytics or advertising SDK. Your recipes and photos stay in the app's private storage on your iPhone (included in your normal device backup).

## License

MIT — see [LICENSE](LICENSE).
