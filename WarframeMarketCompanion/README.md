# Warframe Market Companion (iOS)

A SwiftUI iPhone app to check **item prices**, analyse **Riven auction prices**,
and manage **your own Warframe Market listings** — inspired by PC tools like
AlecaFrame, adapted to what is possible on iOS.

> **Why it can't read your live in-game inventory:** PC tools read the game's
> log files on the same machine. iOS sandboxes every app, so a phone *cannot*
> read Warframe's live inventory. This app uses the public
> [Warframe Market API](https://warframe.market/) instead.

## Features (MVP)

| Tab | What it does |
|-----|--------------|
| **Prices** | Search any tradeable item, see live sell orders (in-game sellers first) + a low/median/avg/high summary. |
| **Rivens** | Pick a weapon, get buyout price stats and every live Riven listing with its rolled stats. |
| **My Orders** | Sign in to warframe.market and review your own buy/sell orders. Token stored in the iOS Keychain. |
| **About** | What the app does and its limits. |

## Project layout

```
WarframeCompanion/
├── Support/      App entry, theme
├── Models/       Codable models (items, orders, rivens)
├── Services/     API client, market/riven/auth services, keychain, stats
└── Views/        SwiftUI screens + view models
```

## Build & run

You need a **Mac with Xcode** (free from the App Store). There are two ways to
get the Xcode project:

### Option A — generate the project with XcodeGen (recommended)

```bash
brew install xcodegen          # once
cd WarframeMarketCompanion
xcodegen generate              # creates WarframeCompanion.xcodeproj
open WarframeCompanion.xcodeproj
```

### Option B — make a fresh project by hand

1. In Xcode: **File ▸ New ▸ Project ▸ App** (SwiftUI, iOS).
2. Delete the auto-generated `ContentView.swift` / `App.swift`.
3. Drag the contents of `WarframeCompanion/` (Models, Services, Views, Support)
   into the project ("Copy items if needed", add to the app target).
4. Build & run.

### Run on your own iPhone (free, no paid account)

1. Plug in your iPhone, select it as the run destination.
2. In **Signing & Capabilities**, pick your personal Apple ID team and set a
   unique bundle id (e.g. `com.<yourname>.warframecompanion`).
3. Press **Run**. With a free Apple ID the app stays valid for **7 days**, then
   you re-run from Xcode to refresh it. A paid Apple Developer account
   ($99/yr) allows TestFlight / 1-year installs.

## Notes / limits

- The Warframe Market sign-in endpoint sits behind anti-bot protection that
  changes over time; if `Sign in` fails, browsing prices and Rivens still works
  without an account.
- Prices come live from warframe.market; respect their rate limits.
- Not affiliated with Digital Extremes or warframe.market.
