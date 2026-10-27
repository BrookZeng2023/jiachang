# 家常 · At Our Table

**A Personal Kitchen Journal**  
记住怎么做，也记住为什么做。  
Recipes to make. Moments to keep.

Jiachang is a private, offline kitchen journal for iPhone. Recipes hold the method; journal pages keep the occasions, people and small changes around each meal. No account, server, streaks or reminders.

## Visual principles

When browsing, it feels like a book. While cooking, it behaves like a tool.

| Token | Value | Use |
|---|---|---|
| cream | `#FDF8F0` | page background |
| paper | `#FFFDFC` | cards |
| ink | `#2E2420` | text |
| persimmon | `#D9542B` | actions and checks: the warmth of a lit stove |
| caramel | `#E8A54B` | amber accents |
| hairline | `#EDE3D7` | rules |
| terracotta | `#B23A20` | errors and destructive actions only |

The palette stays warm on purpose: persimmon orange for anything the cook touches, cream paper behind it. An earlier sage-green pass read as calm but lost the kitchen warmth, so orange is the canonical accent and the app icon keeps its orange gradient.

No simulated paper texture, elaborate borders or page-turn animation. Photos can show ordinary cooking, not just finished plates.

Three font roles are explicit in `Interfaces/DesignSystem/Typography.swift`:
- `emotional`: WenKai for dish names, dates, stories and the kitchen note.
- `reading`: Neo XiHei for ingredients, method and explanatory prose.
- System font: controls, navigation, numeric timers. Latin branding uses the system serif.

Font files are bundled offline and registered by the composition root. `app/scripts/build_fonts.py` renames/subsets the upstream fonts while retaining the common GB2312 repertoire for user-written text; rarer characters fall back to system fonts. Font licenses are bundled separately from the app's MIT source-code license.

## Model and layers

```text
Domain/       Recipe, JournalEntry, JournalDraft, CookingTimer; repository and camera protocols
Application/  RecipeLibrary, CookingSession, PhotoCapture, LanguageController
Adapters/     bundled catalog, local JSON/photos, system camera/image/font adapters
Interfaces/   SwiftUI features, semantic styles, localization
Resources/    read-only catalog, photos, fonts and their licenses
```

A `Recipe` is a stable method. A `JournalEntry` records one occasion and references its recipe by UUID. One recipe has many entries. A dated entry may have a note, a person/people, and its own photo; it does not overwrite the recipe or change its method.

Both recipe and journal protocols are implemented by a single local actor, allowing related writes to commit atomically. Application objects own observable state; views never parse the storage file or ask permission APIs directly.

## Local storage and upgrades

`Application Support/Library/library.json` contains the user's overlay. Photos live beside it in `Images/`.

- Bundled catalog recipes retain stable ids across app releases.
- Edits win over catalog updates; deleted starters stay hidden; new starters appear.
- Restoring a starter drops its recipe override, not its journal.
- Explicitly deleting a recipe deletes its entries and their photos; confirmation explains this. Restoring that starter does not recover the deleted journal.
- Schema v2 adds `journalEntries`. v1 files decode with an empty journal; the next successful write stamps version 2 without losing recipes, deletion markers or image tokens.
- JSON writes are atomic. Photos are written first; failed JSON writes roll back the new photo, and old photos are removed only after a successful commit.
- Unreadable files are moved aside, not overwritten. Device/system backups depend on the user's settings. There is no in-app backup export or sync yet.

The journal home is a reverse-chronological list, not a demand to log every meal. On an empty journal it explains how to record a first page. "What's for dinner?" remains in the cookbook, separate from actual cooking history.

## Cooking mode

`CookingSession` owns step position, ingredient checks and one timer. `CookingTimer` is a value model with an injected clock and deadline-based remaining time; rendering is separate.

- Focused steps use larger reading text. Controls and timers use system typography.
- Minutes in a step are suggestions only. Ambiguous ranges/multiple durations require manual input; bilingual text is not counted twice.
- A timer stays associated with its starting step, even when navigating steps.
- Leaving the foreground pauses it; returning requires explicit resume. The interface states this limitation. Foreground completion emits sound and haptic once. No notification permission, background alarm or guarantee is implied.

## Photos and privacy

`PhotoCapture` depends on `CameraAccess` and `PhotoNormalizer` protocols. The system adapters handle authorization and JPEG normalization. The view bridge only presents the camera. Camera permission is requested after the explicit take-photo action, never on launch. The system photo picker only shares the selected photo. Captured photos are not saved into the system photo library.

No analytics, ads, backend or automatic sharing. Private notes, people and photos are not published. Sharing/export and bookshelves are later work, not decorative inactive tabs.

## Verification

`app/scripts/check.sh` regenerates the Xcode project, builds and runs focused tests. Contract tests cover catalog integrity, font registration/glyph coverage, recipe/journal persistence, v1 migration, cascade deletion, rejected references, image normalization and camera failures. Timer tests inject time and cover pause/resume/completion/boundaries/parsing. One simulator-only UI smoke test writes a uniquely named journal page, relaunches, opens its recipe and cooking mode, and cleans up that page.
