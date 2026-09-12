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
- [ ] Flat greybox test level
- [ ] Hero character controller: movement + 3rd person camera, then add 1st person
      camera toggle
- [ ] Commander camera: top-down, pan (edge/keys) + zoom, no unit control yet
- [ ] Wire `toggle_view` to swap active camera/control scheme between the two — prove
      this feels instant and non-janky before building anything on top of it

## Phase 2 — Worker AI & Resources (Commander side)
- [ ] Resource node scenes (wood, red stone) placed in the level
- [ ] Worker unit: gather → return to drop-off → deposit → repeat (simple state
      machine)
- [ ] RTS selection: click to select a worker, right-click to command
      (move/gather-at-node)
- [ ] `GameState` resource counters update on deposit

## Phase 3 — Base Building
- [ ] Build placement flow: pick building from menu, ghost preview, cost check, confirm
- [ ] Building types: Command Center (already exists as "home"), one Tower, one Tech
      building
- [ ] Upgrade queue: select building → choose upgrade → timer → apply effect
      (e.g. worker speed+, tower damage+)

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
