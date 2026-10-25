# Rhythm model: how it works now, and where to go next

_Written 2026-10-25 after Jared's second M3 playtest._

## Jared's feedback

- Harder to parse. Waves are too short to get real attempts at landing notes, and it doesn't feel telegraphed.
- Testing with Q towers only: the rhythm "isn't great," but it's hard to judge with one real attempt per round.
- Early levels won't train the player: they're short, and the rhythm demand comes out of nowhere.
- Remove hats. The game should have **1-2 rhythms**, with several towers able to make them.
- Idea: a **horizontal timeline** like a DBM / WoW boss-mod timeline that scrolls with the song and shows what's coming.
- Question: do we know when notes will activate ahead of time, or do they activate when enemies pass a tower?

## How M3 picks cues today (the honest answer)

1. The song loops in 4-bar phrases of about 8 seconds each.
2. At the start of bar 3 of each phrase, **only if a wave is running**, the game picks a short rhythm (2-3 notes).
3. For each note it picks a tower **that has an enemy in range at that moment**, preferring towers in crossfire.
4. The chime plays the rhythm (bar 3), then the rings land on those towers (bar 4).

So cues are **enemy-driven**: nothing is known until enemies happen to be near towers when a phrase starts. That's why Jared saw one chance near the start of a wave and one when enemies reached the "hand" of the maze, and nothing in between. It can't be shown ahead of time, because it doesn't exist ahead of time.

## The core choice

| | A. Song-driven (recommended) | B. Enemy-driven (today) |
|---|---|---|
| What decides the notes | A fixed chart that is part of the song | Where enemies are when a phrase starts |
| Known in advance | Yes, so it can be shown on a timeline | No |
| What a note does | Every tower on that key that has a target fires a Resonance. No target means the note is wasted. | Only the one cued tower fires |
| How the maze matters | You build so your Q and E towers are engaged when the chart calls for them. Long corridors and crossfire keep more towers engaged for more notes. | Indirectly, through which tower gets picked |
| Training | The chart can start sparse (wave 1: a few Q notes) and build up. The same song teaches by repetition. | Random. Early waves are too short to learn anything. |
| Fits the timeline idea | Yes | No |

**Recommendation: A, with the timeline, and 2 keys.**

- Drop hats as a playable rhythm. Keep **Q** (on the beat, heavy) and **E** (off-beat, syncopated) as the two rhythms. Hats can stay as background music.
- The song plays continuously, through build phases too. Each wave is a section of the chart: wave 1 has a few Q notes, wave 3 adds E, and later waves mix them into phrases.
- A **timeline strip** scrolls right-to-left under the board with upcoming Q and E notes, like a boss-mod timeline. The rings on towers stay as the "now" moment.
- Pressing a note fires a Resonance from **every** tower on that key that has a target, with a crit on Perfect. That makes the maze question "how many of my Q towers are in the fight when the Q notes come?", which keeps pillar 1.
- Waves get longer (more creeps, spaced out) so each one carries 4-8 phrases of practice.

**Risk:** a visible timeline moves toward "chart reading," which Jared wanted to avoid for bosses (D-0005). Mitigation: keep the timeline for regular waves as training wheels. Bosses can hide it later and rely on tells and music, once players have learned the rhythms from waves.
