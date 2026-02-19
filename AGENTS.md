# Repository Guidelines

## Project Structure & Module Organization
`TimeLapze/` contains the macOS SwiftUI app source (recording logic, models, views, assets, and localization files).  
`TimeLapzeTests/` contains XCTest unit tests for app logic.  
`TimeLapzeUITests/` contains UI tests.  
`TimeLapze.xcodeproj/` holds project settings and shared schemes (`ScreenTimeLapse`, `Test`).  
Repo-level tooling/config includes `.swift-format` (format rules), `typos.toml` (spelling checks), and `timelapze.rb` (Homebrew cask metadata).

## Build, Test, and Development Commands
- `open TimeLapze.xcodeproj`: Open the project in Xcode for local development.
- `xcodebuild -list -project TimeLapze.xcodeproj`: Show targets and schemes.
- `xcodebuild build -project TimeLapze.xcodeproj -scheme ScreenTimeLapse -destination 'platform=macOS'`: CLI build for the app.
- `xcodebuild test -project TimeLapze.xcodeproj -scheme Test -destination 'platform=macOS'`: Run unit/UI tests from CLI (requires valid local signing setup).
- `swift format --in-place --recursive TimeLapze TimeLapzeTests TimeLapzeUITests`: Apply formatter rules from `.swift-format`.
- `typos`: Run typo checks using `typos.toml`.

## Coding Style & Naming Conventions
Use Swift with 2-space indentation and a 100-character line limit (enforced by `.swift-format`).  
Prefer ordered imports and lowerCamelCase identifiers for methods/properties.  
Use UpperCamelCase for types and filenames (for example, `RecorderViewModel.swift`, `PreferencesView.swift`).  
Keep SwiftUI views suffixed with `View` and state/logic objects suffixed with `ViewModel` where applicable.

## Testing Guidelines
Use XCTest for both unit and UI coverage.  
Name test files as `<Subject>Tests.swift` and test methods as `test<BehaviorOrScenario>()`.  
Add tests alongside feature changes, including at least one edge/failure-path assertion for non-trivial logic.

## Commit & Pull Request Guidelines
Recent commits favor short, imperative summaries, sometimes with an issue/PR reference (for example, `Update timelapze.rb` or `Updating readme (#62)`).  
Keep commits focused to one logical change.  
PRs should include:
- A clear description of what changed and why.
- Linked issue(s) when relevant.
- Manual test notes.
- Screenshots or short recordings for UI-visible changes.
- Crash details/logs when fixing stability bugs.

## Security & Configuration Notes
This app uses screen/camera-related macOS APIs; avoid committing personal recordings, local paths, or signing artifacts.  
Do not change signing/team settings unless the change is intentional and documented in the PR.
