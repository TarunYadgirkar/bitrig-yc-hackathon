# Intent — Progress / Handoff

> Status doc for picking up where the last session left off. App code only — no secrets, no planning docs.

**Last updated:** 2026-06-10
**Build status:** ✅ Compiles clean for iOS (verified `xcodebuild` against `iphonesimulator27.0`, zero errors/warnings).
**Deploy status:** ⏳ Not yet run on a physical device — blocked only on signing setup (see "What's left").

---

## What this app is

**Intent** is a native SwiftUI iOS app. You type a plain-English description of an iOS app, it calls the Claude API, and it returns a complete, compilable **App Intents** Swift implementation (so the described app becomes visible to the new AI-powered Siri). Output can be copied or shared.

**Core loop:** describe app → tap *Generate App Intents* → loading → Claude returns Swift → copy/share.

---

## Architecture

State-driven single-screen app. `ContentView` switches views off `viewModel.state`.

```
Intent/
├── IntentApp.swift          ← root (@main)
├── ContentView.swift        ← state switcher
├── Views/
│   ├── InputView.swift
│   ├── LoadingView.swift
│   └── OutputView.swift
├── Services/
│   └── ClaudeService.swift
└── Models/
    ├── GenerationState.swift
    └── SystemPrompt.swift
```

| File | Role |
|------|------|
| `IntentApp.swift` | `@main` entry → `WindowGroup` → `ContentView` |
| `ContentView.swift` | Routes on `viewModel.state`; animates transitions |
| `Models/GenerationState.swift` | `GenerationState` enum (Equatable) + `IntentViewModel` (`@MainActor`, `ObservableObject`) |
| `Models/SystemPrompt.swift` | The system prompt that constrains Claude to raw, compilable App Intents Swift |
| `Views/InputView.swift` | Text editor + Generate button (driven by `canGenerate`), error banner |
| `Views/LoadingView.swift` | Spinner + pulsing text |
| `Views/OutputView.swift` | Dark code view, Copy button (`UIPasteboard`), native `ShareLink` |
| `Services/ClaudeService.swift` | URLSession call to Anthropic Messages API + error handling |

> Note: in the runnable Xcode project these compile from a flat synchronized group; the folder split here mirrors the intended Xcode group layout.

### State machine
```
GenerationState: .idle | .loading | .success(code:) | .error(message:)
  .idle / .error → InputView
  .loading       → LoadingView
  .success       → OutputView(onBack: viewModel.reset)
```
`IntentViewModel` exposes: `appDescription`, `state`, `canGenerate`, `generate()`, `reset()`.
`state` helpers: `isLoading`, `code: String?`, `errorMessage: String?`. A `currentTask` guard prevents double-tap double-calls.

### Claude API
- `POST https://api.anthropic.com/v1/messages`
- Headers: `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`
- Model: **`claude-sonnet-4-6`**, `max_tokens: 2000`, `system: systemPrompt`
- `ClaudeService` checks HTTP status, decodes Anthropic error JSON into a readable message, handles timeouts and empty content (`ClaudeError: LocalizedError`).

---

## Build & run

- **Open in Xcode 27** (this targets iOS 27 / `SDKROOT = auto`).
- **Run on an iPhone or iOS Simulator — NOT "My Mac."** The app uses UIKit (`UIPasteboard`) and iOS-only colors (`Color(.secondarySystemBackground)`, `Color(.systemBackground)`); a macOS build will not compile.
- Build verified with:
  ```
  xcodebuild build -scheme MyApp -sdk iphonesimulator27.0 \
    -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
  ```

---

## Gotchas / environment notes

- **`import Combine` is required.** Xcode 27 / Swift 6 `MemberImportVisibility` no longer re-exports Combine through SwiftUI, so `@Published` / `ObservableObject` need an explicit `import Combine` (in `GenerationState.swift`). Without it: *"type 'IntentViewModel' does not conform to protocol 'ObservableObject'."*
- **No iOS Simulator runtime is installed** in the dev Xcode at last check — either run on a physical device or download the iOS 27 runtime (Xcode → Settings → Components).
- **API key is NOT in this repo.** `ClaudeService.swift` here ships a `YOUR_CLAUDE_API_KEY` placeholder. The real key lives only in the local Xcode project copy and is intentionally never committed (this repo is public). Rotate the key if it is ever exposed.
- **This repo is loose source files**, not a full `.xcodeproj`. The runnable project lives separately on the dev machine as an Xcode "synchronized file group," which auto-includes any `.swift` added to its folder. Keep this repo and that project in sync manually.

---

## What's done

- [x] All 8 source files present and consistent
- [x] State machine + ViewModel wired (`canGenerate`, `reset`, double-tap guard)
- [x] Robust API error handling (HTTP status, timeout, empty content)
- [x] `import Combine` fix for Xcode 27
- [x] Native `ShareLink` for sharing
- [x] Compiles clean for iOS

## What's left

- [ ] Run on a physical iPhone: connect device, enable Developer Mode, add an Apple ID in Xcode → Accounts, set a `DEVELOPMENT_TEAM` + a real bundle id (currently the placeholder `devplaceholder…`) under the MyApp target's Signing & Capabilities, then ⌘R.
- [ ] Test the 4 sample prompts end-to-end against the live API for clean, compilable output.
