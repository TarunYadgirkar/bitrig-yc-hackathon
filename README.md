# Intent — App Intents Code Generator

Native SwiftUI app that turns a plain-English iOS app description into a complete, compilable **App Intents** Swift implementation via the Claude API — so your app becomes visible to the new AI-powered Siri.

## Setup

1. Add your Anthropic API key (kept out of git):
   ```sh
   cp Secrets.swift.example Secrets.swift
   ```
   Then edit `Secrets.swift` and set `anthropicAPIKey`. `Secrets.swift` is gitignored, so your key is never committed.

2. Open in Xcode (built/tested on Xcode 27 / iOS 27; deploys to iOS 16+).

3. Build & run on an **iPhone or iOS Simulator** — not "My Mac" (the app uses iOS-only UIKit APIs).

See [PROGRESS.md](PROGRESS.md) for architecture and current status.
