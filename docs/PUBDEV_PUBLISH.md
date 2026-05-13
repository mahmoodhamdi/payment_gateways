# Publishing to pub.dev

Pub.dev publishing is a manual step. CI prepares everything; an authenticated developer pushes the button.

## Pre-flight checklist

```bash
cd package
flutter pub get
flutter analyze --fatal-warnings
flutter test --coverage
dart format --output=none --set-exit-if-changed .
dart pub publish --dry-run
dart pub global activate pana
dart pub global run pana .
```

All of those should pass / score ≥ 130. If pana flags anything, fix it before publishing.

## First-time-only setup

```bash
dart pub login    # opens browser, signs you in with your pub.dev account
```

## Publish

```bash
cd package
flutter pub publish
# review the diff, confirm with `y`
```

The first publish takes 5–30 seconds and shows up at:

`https://pub.dev/packages/payment_gateways`

## Version bumps

For every release:

1. Update `version:` in `package/pubspec.yaml`.
2. Add a section to `package/CHANGELOG.md` matching the new version.
3. Commit: `chore(package): release v0.X.Y`.
4. Tag: `git tag v0.X.Y && git push origin v0.X.Y`.
5. The `release.yml` workflow builds APKs, optionally pushes the backend Docker image, and creates the GitHub Release.
6. Run `flutter pub publish` manually.

## After publishing

- Verify the listing on pub.dev.
- Check the **Score** tab — pana points, popularity, likes.
- Watch the **Issues** tab for early reports.
- Promote on Twitter, r/FlutterDev, the MENA developer Slacks.

## Unpublishing

You can't permanently unpublish a published version. You can **retract** within 7 days (`flutter pub retract <version>`) which hides it from `pub get` but keeps it discoverable. Use retraction only for actual security or correctness issues, not stylistic regrets.
