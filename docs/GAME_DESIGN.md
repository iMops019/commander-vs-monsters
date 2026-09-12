# Commander Vs Monsters — Game Design Doc

## 1. Pitch

A solo prototype inspired by *Savage: The Battle for Newerth* — the RTS-meets-FPS hybrid
that never found its audience. One side is the **Commander**, playing a top-down RTS:
directing AI workers, gathering resources, building and upgrading structures, and
teching up. That Commander can also drop out of the top-down view and take direct
control of a **Hero unit** in 1st/3rd person to fight monsters for XP and gold, or push
into the enemy base.

The opposing side — the **Monsters** — is entirely AI-driven for this prototype: an AI
Commander that manages its own economy and builds/sends AI monster workers, defenders,
and attackers. There is no second human player yet. The goal of the prototype is to
prove out the core loop (RTS management + direct hero combat, on one side, against a
competent AI on the other) before considering multiplayer, factions, or content scope.

## 2. Inspiration & Why This Genre

*Savage* paired an RTS commander (build orders, tech, base defense) with players fighting
on the ground in first/third person. The genre mostly died out because of steep
onboarding (players had to learn RTS macro AND FPS/action micro at once) and thin
execution on both halves. This project's bet: a single player experiencing **both**
halves themselves (Commander view + Hero view, freely switched) is a much easier way to
feel out whether the loop is fun, without needing a second player or matchmaking to test
it.

## 3. Core Pillars

1. **Two views, one player.** Top-down Commander mode and 1st/3rd person Hero mode are
   both driven by the same player, switching at will (not split-screen, not networked).
2. **Macro feeds micro.** Resources gathered and buildings/upgrades queued in Commander
   mode should visibly matter when playing the Hero (better gear, towers helping you
   push, reinforcements).
3. **The enemy plays the same game.** The AI Monster side runs its own economy/build
   logic, not just scripted spawns — so the prototype also proves out "AI Commander"
   behavior, not just "AI creeps."
4. **Small, provable loop first.** Cut everything that isn't needed to answer: *is
   switching between commanding and personally fighting actually fun?*

## 4. Core Gameplay Loop

```
 ┌─────────────────────────┐        toggle view        ┌──────────────────────────┐
 │      COMMANDER MODE      │ ─────────────────────────▶│        HERO MODE          │
 │  (top-down RTS camera)   │◀───────────────────────── │  (1st/3rd person)         │
 └─────────────────────────┘                            └──────────────────────────┘
   - Assign workers to           - Kill AI monsters for XP/gold
     gather wood / red stone     - Spend gold on gear/abilities at base
   - Queue buildings/upgrades    - Escort/support own workers & towers
   - Place auto-turret towers    - Push into the Monster base, destroy structures
   - Research tech at buildings  - Retreat/heal, hand control back to workers via AI
```

Session shape for the prototype: gather → build up base & defenses → hop into Hero →
farm monsters/XP nearby → gear up → push the AI Monster base while still occasionally
popping back to Commander view to keep the economy/defense running.

## 5. Factions

### Player Side — Commander
- **Commander (the player):** No body in Commander mode (camera/cursor only); becomes
  the Hero's body when switched to Hero mode.
- **Workers (AI, player-directed):** Gather resources (wood, red stone), construct
  buildings when ordered.
- **Towers:** Auto-targeting defensive structures, built by workers on Commander order.
- **Buildings:** Produce/upgrade workers or towers, unlock tech via a simple upgrade
  queue (click building → start upgrade → wait).

### Enemy Side — Monsters (fully AI)
- **AI Monster Commander:** Runs its own economy loop (gather → build → tech) at a pace
  tuned for prototype difficulty, not full parity at first.
- **Monster Workers:** Equivalent of player workers — gather resources for the AI side.
- **Monster Defenders:** Guard the AI base/resources; the Hero fights these for XP/gold.
- **Monster Attackers:** Periodically sent to raid the player's workers/base — this is
  the pressure the player must defend against, either via towers or by returning to
  Commander mode.

## 6. Systems

### 6.1 Resources
- **Wood** and **Red Stone** (rename later if desired) — gathered by workers, spent on
  buildings/upgrades. Two resources is enough to force basic prioritization without
  needing a full economy sim.

### 6.2 Commander Mode (RTS)
- Top-down/angled camera, click-to-select workers/buildings, click-to-command
  (move/gather/build).
- Build menu: worker production, towers, tech buildings.
- Upgrade queue: click a building, choose an upgrade, it completes after a timer.
- Minimal base defense: towers auto-fire at monsters/attackers in range.

### 6.3 Hero Mode (1st/3rd person)
- Camera toggle between 1st and 3rd person (a stated project pillar — keep this
  switch cheap/free, it's a feel choice not a mechanic gate).
- Combat: melee and/or ranged attack against monsters.
- Progression: XP from kills → level/stat increases; Gold from kills/objectives →
  spend on gear at a Commander-mode building.
- Base-push: Hero can damage/destroy AI Monster buildings directly.

### 6.4 View Switching
- Single input (e.g. a key) swaps Commander ⇄ Hero. While in Hero mode, workers keep
  executing their last orders (gather/build) autonomously — no need to babysit both at
  once, but the player can't issue *new* Commander orders until switching back.

### 6.5 AI
- **Worker AI (both sides):** path to resource, gather, return to drop-off, repeat;
  build when ordered/assigned.
- **AI Commander (Monster side):** loop of "assess economy → queue building/worker/
  upgrade → assign defenders/attackers" on a timer or simple utility score. Doesn't need
  to be smart, needs to be *present*, so the base feels like it's run by something.
- **Monster Defender/Attacker AI:** simple aggro/patrol/raid state machine.

## 7. Prototype Scope (Cut Everything Else)

**In scope:**
- One small map, one base per side.
- 2 resources, ~3 building types, 1 tower type, 1 worker type, 1 Hero.
- A handful of upgrades (worker speed, tower damage, hero stat) — enough to prove
  macro→micro payoff, not a full tech tree.
- One monster defender type, one attacker type.
- Win condition: destroy the enemy Commander's main building (or a timer/score stand-in
  if base-destroy isn't ready).

**Explicitly out of scope for now:** multiplayer/networking, multiple factions/races,
matchmaking, cosmetics, sound/art polish beyond placeholders, save/load, multiple maps.

## 8. Open Questions (revisit once the prototype loop is playable)
- Does the player ever *need* to be in Commander mode once base is set up, or does it
  become "set and forget"? May need periodic pressure (raids) to force switching back.
- Is 1st vs 3rd person purely cosmetic, or should one have a mechanical edge (e.g. 1st
  person = better aim, 3rd person = better spatial awareness for dodging)?
- How aggressive should the AI Commander be by default — needs tuning once both loops
  exist.
