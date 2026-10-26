# Jiachang Design Notes · 家常设计说明

## Visual direction: an evening kitchen · 厨房的傍晚

Jiachang treats food photography as the primary interface rather than decoration. The visual system combines warm, saturated colour with restrained information density:

| Token | Value | Role |
|---|---:|---|
| `cream` | `#FDF8F0` | page background |
| `persimmon` | `#D9542B` | primary actions |
| `terracotta` | `#B23A20` | pressed state and emphasis |
| `sage` | `#5F7F52` | completion and ingredient checks |
| `caramel` | `#E8A54B` | small highlights |
| `ink` | `#2E2420` | primary text |
| `muted` | `#8A7A6E` | secondary text |

### Principles

1. **The photo is the card.** Titles sit on a bottom gradient instead of occupying a separate white panel.
2. **Warm, not beige.** Persimmon, sage and caramel carry enough saturation to avoid a generic system-app appearance.
3. **One dominant action.** Add, save and restore use a consistent high-emphasis treatment.
4. **Editorial type.** Serif display type adds cookbook character; system body type protects readability.
5. **Graceful missing-image state.** The generated bowl mark and rotating warm gradients replace emoji and grey placeholders.
6. **Small, useful motion.** Press feedback and ingredient-check animation communicate state without becoming ornamental.

The app icon is reproducibly drawn by `app/scripts/generate-icon.swift`: a white bowl and three steam strokes on a terracotta gradient.

## Layered object architecture

```text
Domain/
  Recipe.swift             recipe entities, origin and editable draft
  Services.swift           repository protocol
  Language.swift           bilingual content selection

Application/
  RecipeLibrary.swift      list/search/detail/save/delete/restore use cases
  LanguageController.swift in-app language state

Adapters/
  Catalog/                 read-only recipes bundled with each release
  Local/                   on-device overlay, photo store and merge rules

Interfaces/
  App/                     composition root
  DesignSystem/            palette, typography, artwork and components
  Features/                focused SwiftUI feature modules
  Localization/            Chinese and English UI copy

Resources/Catalog/         recipes.json and images/<key>.jpg
```

Dependencies point inward: interfaces call application objects, application objects depend on domain protocols, and adapters implement those protocols. Domain code imports neither SwiftUI nor storage frameworks.

## Offline catalog and user overlay

There is no account and no server. Two sources are merged at read time:

1. **Catalog** — `Resources/Catalog/recipes.json`, read-only, replaced by every release.
2. **Overlay** — `Application Support/Library/library.json` plus user photos in `Library/Images/`. It stores only what the user changed: full copies of edited built-ins, personal recipes, and the ids of deleted built-ins.

Built-ins are matched by their stable `id`, so a catalog update can fix wording, add recipes or remove recipes without touching user data:

- edited built-in → user version wins; *Restore original* drops the overlay copy
- deleted built-in → stays hidden; *Restore deleted starter recipes* clears the list
- edited built-in later removed from the catalog → kept as a personal recipe
- unreadable overlay file → moved aside as `library.unreadable-<time>.json`, never overwritten

Writes are atomic; a new photo is written before the overlay and the old photo is removed only after the overlay is saved.

## Data localization

Recipes use a portable delimiter instead of per-field translations:

```text
番茄炒蛋 · Tomato and Egg Stir-fry
```

The app displays the selected side. Recipes without the delimiter are shown unchanged in either language.

## Camera and photo boundaries

The composition root injects `PhotoCapture` with the `CameraAccess` and `PhotoNormalizer` domain protocols. The application object handles permission outcomes and image preparation; `SystemCameraAccess` and `JPEGPhotoNormalizer` implement the platform details. `CameraCaptureView` only bridges the system camera delegate to SwiftUI. Camera permission is requested on the explicit take-photo action, not at launch. Denied or unavailable access leaves the system photo picker usable; captured photos are not written to the system photo library.

Recipe artwork is rendered as an overlay inside its container, so aspect-fill images cannot increase a grid cell's measured width.

## Quality strategy

The test suite stays intentionally small. It covers the contracts most likely to break user data or a release:

- the shipped catalog decodes, ids are unique and every photo exists
- edits, deletions and photos survive a catalog update; restore works
- an unreadable overlay is set aside, not overwritten
- bilingual content selection
- draft normalization

`app/scripts/check.sh` regenerates the Xcode project and runs the focused suite against a caller-selected simulator.
