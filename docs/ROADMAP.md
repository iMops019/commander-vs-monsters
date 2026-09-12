# Commander Vs Monsters — Build Order

Phased setup plan for the solo prototype described in [GAME_DESIGN.md](GAME_DESIGN.md).
Each phase should end in something you can actually run in-editor. Do them in order —
later phases assume earlier ones exist, even in placeholder form.

## Phase 0 — Project Setup
- [x] `git init` the project + push to [github.com/iMops019/commander-vs-monsters](https://github.com/iMops019/commander-vs-monsters)
      (Godot's own `.gitignore`/`.gitattributes`/`.editorconfig` were already present)
- [x] Folder structure: `scenes/`, `scripts/`, `assets/`, `autoloads/`, `docs/` (this
      folder)
- [x] Input Map: `move_forward/back/left/right`, `jump`, `toggle_view` (Commander ⇄
      Hero), `toggle_camera` (1st/3rd person), `primary_action`/`secondary_action`
      (left/right click — reused for RTS select/command in Commander mode and
      attack/block in Hero mode, since the meaning is mode-dependent, not input-dependent)
- [x] Autoloads: `GameState` (resources, view mode, hero/camera refs) and `EventBus`
      (signals for view mode + resource changes) — see `autoloads/`

## Phase 1 — View Switching Skeleton
- [x] Flat greybox test level (`scenes/main.tscn`: ground box, directional light, flat
      ambient environment)
- [x] Hero character controller (`scripts/hero.gd`): WASD + jump, mouse-look, 3rd person
      camera by default with `toggle_camera` switching to 1st person
- [x] Commander camera (`scripts/commander_camera.gd`): fixed top-down-ish angle,
      WASD pans it, mouse wheel zooms (moves camera height) — no unit selection/control
      yet, that's Phase 2
- [x] `toggle_view` wired in `scripts/main.gd` — swaps `GameState.view_mode`, both
      camera scripts and the hero listen for `EventBus.view_mode_changed` and
      activate/deactivate themselves (camera `current`, mouse capture, physics
      processing) accordingly
- [x] Verified headless (`godot --headless --path . res://scenes/main.tscn
      --quit-after 60`) — loads and runs 60 frames with no script/scene errors.
      **Still needs a manual play-test in the editor** to actually feel out the camera
      switch (headless can't confirm "does this feel instant and non-janky")

## Phase 2 — Worker AI & Resources (Commander side)
- [x] Resource node scenes (`scenes/resource_node.tscn` + `scripts/resource_node.gd`) —
      one wood node and one red-stone node placed in `main.tscn` (color-coded, finite
      `amount` that depletes and frees the node)
- [x] Worker unit (`scenes/worker.tscn` + `scripts/worker.gd`): IDLE/MOVING/GATHERING/
      RETURNING state machine — walks to a resource, gathers on a tick, returns to the
      `Stockpile` marker, deposits, repeats automatically
- [x] RTS selection & commanding, added to `scripts/commander_camera.gd`: left-click
      raycasts and selects a worker (green ring), right-click raycasts and either
      commands gather (hit a resource node) or plain move (hit anything else, e.g. bare
      ground)
- [x] `GameState.add_resource()` called on deposit — resource counters update, verified
      no script/scene errors headless. **Still needs an in-editor play-test**: select the
      worker, right-click the wood/red-stone node, watch it gather and return

## Phase 3 — Base Building
- [x] Build placement flow (`commander_camera.gd`): HUD button → transparent green
      "ghost" follows the mouse raycast on the ground → left-click confirms if
      affordable (deducts cost, spawns the real building) → right-click/Escape cancels
- [x] Building types: Command Center (still the `Stockpile` placeholder from Phase 2 —
      no separate scene needed yet), `scenes/tower.tscn` (40 Wood/20 Red Stone,
      groups "buildings"/"towers" — auto-fire logic is Phase 6), `scenes/tech_building.tscn`
      (30 Wood/40 Red Stone, groups "buildings"/"tech_buildings")
- [x] Upgrade queue, in `scripts/tech_building.gd`: select a Tech Building → HUD upgrade
      panel appears → click an upgrade → cost deducted, timer runs → applies
      `GameState.worker_speed_multiplier` or `.tower_damage_multiplier` (the latter has
      no effect yet until Tower combat exists in Phase 6, but the pipeline is in place)
- [x] `scenes/hud.tscn` + `scripts/hud.gd` added: resource readout, build buttons,
      upgrade panel — only visible in Commander mode. Verified headless, both new
      building scenes also load standalone with no errors. **Still needs an in-editor
      play-test**: place a Tower and a Tech Building, select the Tech Building, run an
      upgrade, confirm the worker speeds up afterward

## Phase 4 — Hero Combat
- [x] Shared `Health` component (`scripts/health.gd`, global class `Health`) — a plain
      Node with `apply_damage`/`heal`/`reset`/`died` signal, added as a child to any
      entity that needs HP. Hero now has one; Phase 5 monsters will reuse it
- [x] Hero attack (`hero.gd`): one melee-range raycast on `primary_action`, on a
      cooldown, forward from whichever camera (1st/3rd) is active
- [x] XP + Gold on kill: added `scenes/training_dummy.tscn` (group "hostile", 50 HP,
      respawns a few seconds after death) purely as something to hit, since Phase 5's
      real monsters don't exist yet. On death it calls `GameState.add_hero_xp()` /
      `add_resource("gold", ...)`; `add_hero_xp` handles leveling up
- [x] Gear/upgrade spend screen: **folded into the existing Tech Building upgrade
      panel** rather than adding a third building — it's already a Commander-mode
      building with an upgrade queue, so two new Gold-cost upgrades (`hero_damage`,
      `hero_health`) were added there instead of building a separate screen. HUD
      resource line now also shows Hero level/XP so kills are visible without leaving
      Commander mode. Verified headless (note: adding `class_name Health` required one
      `--headless --editor --quit` pass to register the global class before it would
      resolve — expected one-time step, not a bug). **Still needs an in-editor
      play-test**: hit the dummy a few times as Hero, confirm it dies/respawns and
      Gold/XP tick up, then switch to Commander and spend Gold on a Hero upgrade

## Phase 5 — Monster AI Side
- [x] Monster Worker: **reused `scenes/worker.tscn`/`scripts/worker.gd` for both
      factions** rather than duplicating the gather state machine — added a `faction`
      field, a `Health` child (so it's killable), and generalized the deposit call to
      `stockpile.deposit(...)` (a duck-typed method now on both `stockpile.gd` and
      `monster_commander.gd`) instead of hardcoding `GameState.add_resource`. Monster
      workers compete for the *same* wood/red-stone nodes as the player's — no separate
      resource set was added. Fixed a related bug while doing this: RTS click-selection
      in `commander_camera.gd` was checking group "workers" (which now includes enemy
      workers too) — narrowed to "player_workers" so you can't select/command the enemy's
- [x] AI Commander loop (`scripts/monster_commander.gd`): every 5s, a priority list —
      spawn worker (if under cap & affordable) → else spawn attacker → else spawn
      defender → else spend on a random internal upgrade (attacker or defender damage
      multiplier). Has its own `wood`/`red_stone` pool, separate from the player's
      `GameState` fields (mirrors the "AI runs its own economy" pillar). Also
      reassigns idle monster workers to the nearest remaining resource node each tick
- [x] Monster Defender (`scripts/monster_defender.gd`): GUARDING → CHASING → ATTACKING →
      RETURNING around a fixed guard post, with a leash range so it won't chase forever.
      Deals damage to the Hero directly (scaled by the AI's `defender_damage_multiplier`)
      — this goes a bit beyond the roadmap's plain "guard/aggro" wording, but a defender
      that can't fight back would just be another training dummy, and Hero-vs-Defender
      combat is the core of the GDD's "farm monsters for XP" loop
- [x] Monster Attacker (`scripts/monster_attacker.gd`): RAIDING → LINGERING → RETURNING —
      walks from the monster base to the player's Stockpile, waits there a while, then
      walks home and despawns. **Deliberately does not deal damage yet** — the roadmap
      puts "Attackers actually damage player workers/buildings" in Phase 6, so this
      phase only proves the pathing/raid-timing behavior
- [x] All monster units (worker/defender/attacker) are in group "hostile" and grant
      Hero XP/gold on death, same pattern as the Phase 4 training dummy (which is still
      in the scene as an isolated damage-test target). Verified headless over ~16
      simulated seconds (multiple AI decision cycles: worker spawn, attacker raid
      reaching the player base, etc.) with no errors. **Still needs an in-editor
      play-test**: watch the enemy base produce units over time, let a monster worker
      path to a resource node, get raided by an attacker, and fight a defender as Hero

## Phase 6 — Combat Glue & Win Condition
- [x] Towers auto-target and fire (`tower.gd`): an `Area3D` detection radius tracks
      anything in group "hostile" that enters/exits range, fires at the nearest one on
      a cooldown (damage scaled by the Phase 3 `GameState.tower_damage_multiplier`,
      which finally does something), with a brief tracer line for feedback. Verified
      in isolation against the training dummy, including through a full death/respawn
      cycle, since no Tower exists in the default scene for the normal headless run to
      exercise
- [x] Attackers now actually damage things (`monster_attacker.gd`): while LINGERING at
      the player base, it periodically hits the nearest thing in range among
      "player_workers"/"buildings"/"stockpile" that has a `Health` component
- [x] Health added to every building so the above has something to act on: Tower and
      Tech Building (80 HP, permanently destroyed — `queue_free` — since losing a
      placed building to a raid is meant to sting), and the player's Stockpile (150 HP,
      **resets instead of being destroyed** — a deliberate scope cut, see note below)
- [x] Hero can damage/destroy Monster buildings: **found and fixed a real bug while
      wiring this up** — `MonsterCommander` was a bare `Node3D` with no collision body,
      so Hero's raycast attack would have passed straight through it and this
      requirement silently wouldn't have worked at all. Changed it to `StaticBody3D`
      with a `CollisionShape3D`, gave it 200 HP, and added it to group "hostile"
- [x] Win condition (`scripts/win_screen.gd`, `scenes/win_screen.tscn`): Monster
      Commander's `Health.died` emits a new `EventBus.game_won` signal; the win screen
      shows, pauses the tree (`get_tree().paused`), forces the mouse visible (in case
      you were in Hero mode with the cursor captured), and a Restart button reloads the
      scene. Verified directly (apply lethal damage to the Monster Commander's Health
      in isolation, confirmed the screen appears and the tree pauses) since the full
      playthrough to actually kill it takes a while
- Scope note: the player's Stockpile intentionally **cannot be permanently destroyed** —
  there's no lose/game-over flow in this roadmap (only a win condition was ever asked
  for), and permanently destroying the only deposit point would soft-lock the economy
  with nothing to recover into. This mirrors how Hero death is a respawn, not a game
  over. Revisit if a full win/lose flow becomes a goal later. **Still needs an
  in-editor play-test**: build a Tower and confirm it fires on a wandering monster,
  let an Attacker's raid actually chip your Stockpile/buildings, and go destroy the
  Monster Commander as Hero to see the win screen for real

## Phase 7 — Playtest & Tuning Pass
- [x] Map rework (started early, ahead of the rest of this phase): the battlefield is
      now a long corridor rather than a 40x40 square — ground resized to 70 wide x 260
      long (`main.tscn`), player Stockpile/Hero/Worker/dummy at the south end (z≈-110),
      Monster Commander at the north end (z≈110), the two resource nodes centered at
      z=0 as contested ground between the bases
- [x] Border/edge (`scripts/map_border.gd`): a `MapBorder` node procedurally builds 4
      tall box walls around the perimeter at `_ready()`, parametrized by
      `map_width`/`map_length` so resizing the map again doesn't mean hand-editing wall
      geometry. These are a **deliberate placeholder** — solid collision + a rock-grey
      color so the map reads as bounded, meant to be swapped for real Meshy cliff
      meshes later while keeping the same collision shapes
- [x] Ground given a grass-green placeholder material instead of default grey, since
      that's a free readability win while waiting on real terrain/textures
- [x] Retuned `commander_camera.gd` for the new scale: `PAN_SPEED` 12→40, `ZOOM_STEP`
      1.5→4, height range 6–30 → 10–100. Old values would have made panning/zooming
      across a map this size unusably slow
- Real Meshy trees/stone/cliffs are not in the project yet (checked `assets/` —
  still empty) — this phase's greybox placeholders are what they'll replace once
  generated. Verified headless with no errors
- **Balance heads-up, not yet acted on**: at the new scale, a worker's round trip from
  the player Stockpile to the nearest resource node (~110 units each way, 3.5 units/s)
  is roughly a minute for a 10-unit haul, and Hero crossing the full battlefield
  (5 units/s over 260 units) takes about 50 seconds. That may be exactly the slower,
  more strategic pace a "HUGE" battlefield should have — but it's different enough
  from the old 40x40 map that it's worth a real playtest before deciding whether
  worker speed/carry capacity or resource placement need retuning
- [ ] Tune AI Commander pacing/aggression against your own econ pace
- [ ] Revisit the open questions in [GAME_DESIGN.md §8](GAME_DESIGN.md#8-open-questions-revisit-once-the-prototype-loop-is-playable)
      now that both loops actually exist to test against
