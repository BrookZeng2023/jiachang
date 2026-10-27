# Contributing

Thanks for helping improve Jiachang.

## Development

1. Install Xcode and XcodeGen: `brew install xcodegen`
2. Run `cd app && xcodegen generate`
3. Open `app/jiachang.xcodeproj`
4. Keep changes within the existing layers:
   - `Domain`: models and protocols only
   - `Application`: use cases and observable state
   - `Adapters`: bundled catalog and on-device storage
   - `Interfaces`: SwiftUI and localization
5. Built-in recipes live in `app/jiachang/Resources/Catalog/`. Never change an existing recipe `id`; user edits and deletions are matched by it.

## Before a pull request

```bash
cd app
IOS_DESTINATION='platform=iOS Simulator,name=<your simulator>' ./scripts/check.sh
```

Keep tests focused on contracts and failure paths. Avoid redundant UI snapshot tests and avoid committing credentials, generated Xcode projects or local signing-team identifiers.

For new user-facing text, update both `zh-Hans.lproj/Localizable.strings` and `en.lproj/Localizable.strings`.
