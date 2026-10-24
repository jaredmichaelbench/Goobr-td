# Notes: competition and technical feasibility

Pulled from the pitch scratchpad (AI-generated research, not yet verified by us).

## Competition to know

- **Emberward**: tetromino maze-building + roguelite card drafting. Brought mazing back; combat is hands-off.
- **Axon TD: Uprising** (Element TD 2 team): draw/extend terrain tiles for pathing. Strategic, zero action.
- **GemCraft** (Chasing Shadows, Frostborn Wrath): gold standard for chance-based gem upgrades. Semi-fixed paths.
- **X-Morph: Defense**: laser fences route enemies while you fly a ship. Closest mazing + action blend, but it's a twin-stick shooter on top of a TD.
- **Timemelters**: real-time hero tactics with time loops, no mazing.
- **Poker TD**: the "dynamic upgrades with chance" inspiration.
- **Expedition 33**: the inspiration for timing layered on a tactical core.
- **Line Tower Wars (WC3), Tetris 99**: multiplayer inspiration.

Unclaimed space: a grid maze where the towers and nodes are instruments you play in real time.

## Technical notes

- **Rhythm timing**: drive beats from the audio DSP clock (Unity `AudioSettings.dspTime` or FMOD's musical clock), never frame delta. Windows audio latency varies widely; a calibration screen is mandatory.
- **FMOD Studio**: free for indies under $200k/yr revenue (verify current terms). Makes stem muting, quantized transitions, and tempo sync much easier.
- **Engine**: Unity + FMOD (first-party FMOD, Steamworks.NET/Facepunch, mature netcode) vs. Godot 4 (GodotSteam, community FMOD extension, lightweight). Jared develops on a Mac Studio and a PC.
- **Multiplayer**: parallel boards mean no lockstep or rollback. Send small command packets over Steam Datagram Relay (NAT traversal, hidden IPs, no server bill).
- **macOS shipping**: Universal 2 or arm64 builds; Developer ID signing and notarization via `notarytool` ($99/yr Apple Developer account). Steam Input for controllers.
