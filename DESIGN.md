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
3. **One dominant action.** Add, save and reconnect use a consistent high-emphasis treatment.
4. **Editorial type.** Serif display type adds cookbook character; system body type protects readability.
5. **Graceful missing-image state.** The generated bowl mark and rotating warm gradients replace emoji and grey placeholders.
6. **Small, useful motion.** Press feedback and ingredient-check animation communicate state without becoming ornamental.

The app icon is reproducibly drawn by `app/scripts/generate-icon.swift`: a white bowl and three steam strokes on a terracotta gradient.

## Layered object architecture

```text
Domain/
  Recipe.swift             recipe entities and editable draft
  Services.swift           repository, session and credential protocols
  Language.swift           bilingual content selection

Application/
  SessionController.swift  connection lifecycle
  RecipeLibrary.swift      list/search/detail/save/delete use cases
  LanguageController.swift in-app language state

Adapters/
  Mealie/                  HTTP transport, DTOs and repository adapter
  Persistence/             Keychain-backed credentials

Interfaces/
  App/                     composition root
  DesignSystem/            palette, typography, artwork and components
  Features/                focused SwiftUI feature modules
  Localization/            Chinese and English UI copy
```

Dependencies point inward: interfaces call application objects, application objects depend on domain protocols, and adapters implement those protocols. Domain code imports neither SwiftUI nor networking frameworks.

## Data localization

Mealie does not currently expose per-field translations. Starter data therefore uses a portable delimiter:

```text
番茄炒蛋 · Tomato and Egg Stir-fry
```

The app displays the selected side; Mealie's web UI remains readable without a custom plugin. User-created recipes without the delimiter are shown unchanged in either language.

## Quality strategy

The test suite stays intentionally small. It covers the contracts most likely to fail across a Mealie upgrade:

- tolerant DTO decoding, including string-or-integer duration
- bilingual content selection
- draft normalization
- authentication error mapping
- server error mapping

`app/scripts/check.sh` regenerates the Xcode project and runs the focused suite against a caller-selected simulator.
