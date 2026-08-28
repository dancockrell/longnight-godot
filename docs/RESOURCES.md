# External resources — what was found, what was used, what wasn't

Compiled 27-28 Aug 2026 while building out the game's structural/mechanical
layer. Kept as a durable list so a future session does not re-search for
the same things, per Dan's request to "build a list of resources you find
and post for yourself."

## Used, in the repo now

- **GODOT-VFX-LIBRARY** — `github.com/haowg/GODOT-VFX-LIBRARY`, MIT licence
  (verified: root `LICENSE` file, plain MIT, no split licence for the
  bundled art). Cloned to `vendor/vfx-library/` for reference; the actual
  shaders used are copied into `assets/vfx/`:
  - `flash_white.gdshader` — hit-flash feedback in `battle_screen.gd`.
  - `fog.gdshader` — atmospheric wash in `battle_screen.gd`, driven by an
    engine-generated `NoiseTexture2D` (no external image needed).
  - `outline_glow.gdshader`, `dissolve.gdshader` — copied, not yet wired
    into anything. Candidates for a future transition or highlight effect.
  - The library has ~35 more particle effects (`torch_fire`, `sparks`,
    `lightning_chain`, `energy_barrier`, `magic_aura`, `steam`,
    `portal_vortex`, and others) not yet used. Worth a pass when Current
    pillar (Tesla-flavoured) and Chrono pillar (portal/retrieval) VFX get
    built — several of these map almost directly onto those pillars.

## Found, not used — real candidates for later

- **Kenney.nl UI Audio / Impact Sounds / Interface Sounds** (CC0,
  `kenney.nl/assets/ui-audio`, `.../impact-sounds`, `.../interface-sounds`).
  Attempted a direct download via a guessed CDN URL and got an HTML error
  page, not the archive — Kenney's asset URLs are not stable/guessable.
  **Action for whoever picks this up: browse `kenney.nl/assets` directly
  and download the zip through the site**, rather than trying to script
  the fetch. CC0, no attribution required, safe to drop into
  `assets/audio/ui/` whenever real UI sound effects are wanted. This
  project's ambience (`scripts/core/ambience.gd`) is procedural on
  purpose (matching the original canvas game's synthesized-audio
  discipline) but UI clicks/confirms are a reasonable place to use real
  short SFX instead.
- **GDQuest's godot-4-VFX-assets** — code MIT, art CC-BY-NC-SA 4.0. The
  non-commercial art licence makes this a poor fit if this project is ever
  sold; noted and skipped for that reason, not for quality.

## Explicitly needed but not found in the shared canon repo yet

- **`HY-THE-FUSED-ROSTER.md`** — referenced by
  `world-aflame-godot/docs/WORLD-HYAKKI-YAKO.md` §7a as the file that fixes
  Hyakki Yakō's 25 canon fused forms, the same way `WORLD-BESTIARY.md` §6a
  fixes Werk Nachtigall's 24. **Does not exist in the repo as of this
  writing.** The lore itself flags this faction as needing a stricter guard
  than the bestiary ("the roster is a list of what was done to people, and
  the moment it reads as a bestiary this faction has become the
  caricature"), so `scripts/data/enemies.gd`'s Hyakki Yakō roster is
  deliberately thin (two Fog-branch disorientation effects, no named
  monster forms) until that file exists. Check for it before expanding
  Hyakki Yakō combat content.

## Not pursued

- Freesound.org / Pixabay / Soundsnap paper-rustle and page-turn SFX —
  real candidates for UI polish, not pursued this pass because this
  project's UI sound is currently silent rather than procedural-only
  (unlike ambience), so there was no existing system to slot these into
  yet. Worth a look alongside the Kenney UI audio pass above.
