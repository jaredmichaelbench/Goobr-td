# iPad / iOS build: how far away are we? (2026-11-03)

Jared asked: in its current state, how far is the game from an iPad build, if we release on Steam (Mac/Windows) and on iOS/iPad?

Checked against branch `claude/project-thread-ifc428` at commit 1301ef5 (HUD quick list, D-0064). This is an assessment only. Nothing in the build changed.

## Short verdict

- **Getting it to run on an iPad: close.** A few days of setup, mostly on Jared's Mac. The engine settings already suit an iPad.
- **Making it playable and fun on an iPad: far.** Every control is a keyboard key or mouse action (about 40 keys, mouse wheel, Shift-click, right click, hover menus) and there is no touch code at all. A touch version is a real design job, roughly 4 to 8 weeks of work plus playtesting, not a port.
- **Recommendation:** ship Steam (Mac/Windows) first. Don't start iPad work now. Do adopt a few cheap habits now (below) so the iPad version stays cheap later, and do a one-day "does it run on my iPad" check once the demo is locked.

## What already works in our favour

| Area | State | Why it matters |
|---|---|---|
| Renderer | `gl_compatibility` (the simplest Godot renderer) | It runs on iPads and phones. No change needed to boot. (Apple has deprecated OpenGL but it still runs; Godot's Mobile renderer, which uses Apple's Metal, is an option later if needed.) |
| Texture format | ETC2/ASTC import already on | That is the texture format iPads want. |
| Screen stretch | `canvas_items` + `expand` | The UI scales to any screen. iPads are 4:3, not 16:9, so the board gets extra space top and bottom; layouts need a check, not a rewrite. |
| Performance | Stress test after the L2 perf pass: about 17 ms a frame on a cloud CPU | Any iPad with an M-series or recent A-series chip should cope. Older iPads need a real test. |
| Rhythm clock | `BeatClock` reads the audio clock and subtracts the output latency the device reports | This is the right design for iPad too. |
| Engine | Godot 4.5 exports to iOS out of the box | No plugins needed for a first build. |

## What blocks a playable iPad version

### 1. Controls (the big one)

The game reads keys and mouse buttons directly (`KEY_Q`, `KEY_SPACE`, `MOUSE_BUTTON_WHEEL_UP` and so on in about 15 scripts). It uses no Godot "input actions" and no touch events. Things with no touch equivalent today:

- **Q / E notes and Space parry/counter.** These are timing inputs, so they need big on-screen buttons placed under the thumbs (left thumb Q, right thumb E, a wide parry pad). This is the most important design question for iPad.
- **B build mode + mouse wheel to cycle towers.** Needs a tap-to-open tower tray.
- **Shift-click to chain builds.** Needs a "keep building" toggle or drag-to-paint walls.
- **Hover menus, the cursor card, tooltips.** A finger cannot hover. Info needs to show on tap or long-press instead.
- **Right click, Esc, U/I forks, X sell, Tab, number keys.** Each needs a visible button.
- **Fingers cover the board.** With a 65 degree camera and the whole board in view, towers may be too small to tap. Likely needs pinch-zoom or bigger tiles on iPad.

Two-thumb rhythm buttons plus tapping the board at the same time is a genuine design problem, not just wiring. A keyboard on an iPad would work almost as-is, but most players won't have one.

### 2. Rhythm timing on touch

- **Calibration is hard-coded** to Jared's Mac Studio (46 ms, `Timing.FIXED_CALIBRATION`). Every iPad, and every pair of headphones, differs. iOS needs a per-device calibration screen (the beat test from M1 is a starting point).
- **Bluetooth headphones (AirPods) add roughly 150 to 250 ms of delay.** Perfect is 35 ms and Good is 90 ms, so without calibration the game is unplayable on AirPods. Rhythm games on iPad all handle this with a calibration step and a "wired or speaker recommended" note.
- **Touch adds its own delay** (often a few tens of ms). Calibration covers it, but it should be measured on a real iPad before promising the same windows as on Mac.

### 3. Audio files and the custom music idea

- Songs are 15 to 30 MB WAV files loaded by file name from `res://audio`. On iOS they should be packed as compressed OGG files inside the app, or the download gets huge.
- The "drop your own songs and sound packs in a folder" feature (D-0031, backlogged as community custom music) is natural on PC. On iPad, apps are sandboxed; it can work through the Files app, but it is extra work and an App Store review question.
- **VOiD1 licence (T-020)** must cover mobile app store distribution, not just Steam. Ask when we contact them.

### 4. UI size

Many text sizes are 10 to 15 px at the 1280x720 base. On an iPad the screen scales up so it is readable, but touch buttons need to be at least about 44 points (Apple's guideline). The bottom panel, card, and talent tree would need a touch layout pass.

## What an iOS export needs (the admin side)

1. **Apple Developer Program**: $99 a year, in Jared's name or a company's. The same account also lets us sign and notarise the Mac build for Steam, which removes the "Open Anyway" Gatekeeper step testers hit today. So it is worth buying before the Steam demo even without iPad.
2. **Xcode on the Mac Studio** (free, large download). Godot exports an Xcode project; Xcode builds and signs it. This step can't run in the cloud, so it happens on Jared's Mac (a Remote Control session can drive it).
3. **Godot iOS export templates** (one download inside Godot).
4. **A test iPad** registered to the account. Plug it in and run from Xcode.
5. **TestFlight** for wider testers: upload from Xcode, up to 10,000 testers by link, first build gets a short Apple review.
6. **App Store review**: privacy "nutrition label" (we collect nothing, which keeps it simple), age rating questionnaire, screenshots for iPad sizes, a support URL. First reviews usually take a day or two; rejections are common on a first try and usually small.

## Steam vs App Store: business points

| | Steam (Mac/Windows) | App Store (iPad) |
|---|---|---|
| Entry fee | $100 per game (Steam Direct, recoupable after $1,000 in sales) | $99 a year (Developer Program) |
| Store cut | 30% (lower only above $10M) | 15% under the Small Business Program (under $1M a year), else 30% |
| Price norms | Premium indie TD: $10 to $20 is normal | Premium games sell, but buyers expect $5 to $10 and compare to free-to-play. Apple Arcade is an alternative route with a deal up front, by pitch only |
| Discovery | Wishlists, Next Fest demo, festivals | Featuring by Apple matters a lot; hard to plan for |
| Demo | Free demo on its own store page | No real demos; usually a free download with a one-time unlock |
| Multiplayer (backlogged) | Steam networking (planned) | Would need Game Center or our own servers; cross-play is extra work |
| Controllers | Steam Input (backlogged) | iPads support controllers too; controller support would help both |

Rough take: Steam is the main market for a premium rhythm TD. iPad is a good second platform for this genre (tower defense sells well on tablets) but only once the touch design is solved.

## Cheap things to do now so iPad stays cheap later

These are suggestions, not decisions. They also help Steam (key rebinding and controller support).

1. **Move keys to Godot input actions** (`note_q`, `parry`, `build_mode` and so on) instead of raw key codes. Then touch buttons, controllers, and rebinding all feed the same action. Half a day or a day, best done when the HUD settles.
2. **Never put information only in a hover.** Anything a hover shows should also show on click/tap. This fits the HUD work happening now.
3. **Bring calibration back as a setting before any public build.** Needed for Steam players anyway, since they won't have Jared's Mac.
4. **Keep the 4:3 shape in mind** when placing HUD corners.
5. **Ship songs as OGG in exports** (smaller downloads on Steam too).

## Rough plan if we go for iPad later

| Step | Size | Notes |
|---|---|---|
| A. "Does it run" spike | 1 to 2 days | Developer account, Xcode, export, run on Jared's iPad with a keyboard |
| B. Input actions refactor | 1 day | Can happen any time |
| C. Touch control design doc | 1 week incl. discussion | Thumb buttons, tower tray, tap-for-info, zoom; Jared marks up |
| D. Touch build + touch HUD | 2 to 4 weeks | Plus playtests on the iPad |
| E. Calibration flow for touch + Bluetooth | 2 to 3 days | |
| F. Store setup, TestFlight, review | about 1 week elapsed | Mostly waiting on Apple |

Total: about 4 to 8 weeks once the Steam game is stable, mostly step D. Steps B and E pay off for Steam as well.

## Open questions for Jared

- Do you own an iPad to test on, and which model?
- Should the Apple Developer account be in your name or a company's? (Matters for the store listing and for Mac notarisation.)
- Should the cheap habits above go on the backlog, or straight into the next UI pass?
