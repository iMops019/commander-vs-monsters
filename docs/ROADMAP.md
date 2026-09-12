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
- [ ] Shared Health/Damage component (used by Hero, workers, monsters, buildings)
- [ ] Hero attack (start with one attack type — melee or ranged, not both)
- [ ] XP + Gold on kill; simple level-up (flat stat bump is fine)
- [ ] Gear/upgrade spend screen tied to a Commander-mode building

## Phase 5 — Monster AI Side
- [ ] Monster Worker: same gather loop as Phase 2, no player input, runs on its own
- [ ] AI Commander loop: a timer-driven decision step (build worker vs building vs
      upgrade vs assign attacker) — a basic priority list is enough, no need for real
      utility AI yet
- [ ] Monster Defender: guard/aggro state machine near its base/resources
- [ ] Monster Attacker: raid state machine that paths to the player's base periodically

## Phase 6 — Combat Glue & Win Condition
- [ ] Towers auto-target and fire at monsters in range
- [ ] Attackers actually damage player workers/buildings when they arrive
- [ ] Hero can damage/destroy Monster buildings (enables the "push" part of the loop)
- [ ] Win condition: destroy enemy Command Center → end screen/restart

## Phase 7 — Playtest & Tuning Pass
- [ ] Placeholder art/audio only where it affects readability (can't tell what's a
      resource vs a monster, etc.) — skip anything purely cosmetic
- [ ] Tune AI Commander pacing/aggression against your own econ pace
- [ ] Revisit the open questions in [GAME_DESIGN.md §8](GAME_DESIGN.md#8-open-questions-revisit-once-the-prototype-loop-is-playable)
      now that both loops actually exist to test against

---

**Next concrete step:** Phase 0 — want me to go ahead and set up the git repo, folder
structure, and input map now?
