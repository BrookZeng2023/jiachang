# 家常 · At Our Table

**A Personal Kitchen Journal** — Recipes to make. Moments to keep.

记住怎么做，也记住为什么做。一个离线的中英双语厨房手记：打开就能用，不用登录，也不需要服务器。

<p align="center">
  <img src="docs/screenshots/home-zh.jpg" width="320" alt="家常中文首页">
  &nbsp;&nbsp;
  <img src="docs/screenshots/cookbook-en.jpg" width="320" alt="Jiachang English cookbook">
</p>

## Features · 功能

- Native SwiftUI app for iOS 18+
- Works offline out of the box: 16 bilingual starter recipes and photos ship inside the app
- In-app **中文 / English** switching
- Photo-first journal timeline, cookbook, recipe detail and editor screens
- One recipe, many dated cooking notes: who you cooked for, what changed, and a photo
- Focused cooking mode with large step text, ingredient checks and a foreground-only timer
- Warm cream paper and persimmon orange; WenKai for stories, Neo XiHei for method, system type for controls
- Add, edit and delete any recipe, including the starter set; changes stay on the device
- Take a recipe photo or choose one with the system photo picker; camera access is requested only when you choose to take a photo
- About Jiachang includes a message from Brook, privacy and data-storage notes, permission explanations, food-safety guidance and licensing information
- New starter recipes arrive with each app release

---

- iOS 18+ 原生 SwiftUI
- 开箱即用：16 道中英双语家常菜和配图随 app 内置
- 应用内即时切换中文 / English
- 首页按日期翻阅下厨手记；菜谱和每次做饭的记录彼此独立
- 「又做了一次」记录为谁做的、这次改了什么和那顿饭的照片
- 全屏烹饪模式：大字单步、食材勾选、应用内计时器
- 离开前台会暂停计时，返回后手动继续；不发送系统通知，不是后台厨房闹钟
- 文楷负责故事，新晰黑负责阅读，系统字负责操作；暖米白纸色与柿橙点缀
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

The overlay schema is now v2. Existing v1 libraries load with no journal pages and keep their edits, deleted starters and photo references; the next successful save writes v2. Restoring a starter leaves its journal alone. **Deleting a recipe also deletes its journal pages and their photos** after a confirmation; bringing the starter back does not restore those pages.

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

## Typography · 字体维护

The shipped fonts are renamed derivatives: `JiachangKai-{Regular,Medium}` from LXGW WenKai GB v1.530, and `JiachangHei-Regular` from LXGW Neo XiHei v1.308. They keep the common GB2312 repertoire, catalog text and both UI string tables; rarer user-written characters can fall back to iOS fonts. English branding uses the system serif, and controls keep system typography.

To rebuild after changing copy, download those official release fonts plus their respective licenses into a local source folder, then run:

```bash
cd app
uv run --no-project --with fonttools==4.60.1 python -I scripts/build_fonts.py /absolute/path/to/font-sources
```

The source folder needs `LXGWWenKaiGB-Regular.ttf`, `LXGWWenKaiGB-Medium.ttf`, `OFL.txt`, `LXGWNeoXiHei.ttf`, and its `LICENSE.md` saved as `IPA-Font-License.md`. The source font repositories are [WenKai GB](https://github.com/lxgw/LxgwWenkaiGB) and [Neo XiHei](https://github.com/lxgw/LxgwNeoXiHei). Generated font files and licenses are committed; source fonts are not required for ordinary builds. The glyph-coverage test catches copy changes that need a rebuild.

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
- a version 1 library upgrades to version 2 without losing data
- journal pages follow their recipe: adding, deleting and cascade deletion
- an unreadable library file is set aside instead of overwritten
- bilingual content selection and recipe-draft normalization
- the cooking timer parses durations, fires once and never auto-resumes

Simulator-only UI smoke test (`jiachangUITests`) covers the hand-off between them: write a journal page, relaunch, find it on the timeline, open its recipe, enter cooking mode and delete the page again.

```bash
xcodebuild test -project jiachang.xcodeproj -scheme jiachang \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:jiachangUITests
```

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
