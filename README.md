# Chemistry

NPC autonomy for Fallout 4: adult NPCs occasionally start AAF scenes with each other,
because they chose to rather than because a perk was sprayed on them.

**Requires [Rapport](../fo4-rapport).** Chemistry decides; Rapport does.

## What belongs here

The policy. When a pair is worth acting on, how often, what a settlement should feel like,
what the player should and should not walk in on.

## What does not belong here

Anything a second mod would also need. Actor enumeration and filtering, the AAF bridge,
scene requests, the busy-flag discipline, persistent attraction, cooldowns, refusal memory,
the spot finder, the co-save — all of that is Rapport's, and Player Proposals will want every
one of them too.

If something here starts looking useful to another mod, it is in the wrong repository.

## Status

First version written, never run. Rapport's addon API landed today and Chemistry is
two files against it: a generated esp with one quest, and one script.

Decisions are in `DESIGN.md`. One thing in there is an assumption rather than a
decision -- which scenario suits which surroundings -- and it is marked as such.

    python tools/make_esp.py data/Chemistry.esp
    scripts/build-papyrus.ps1
    scripts/deploy-dev.ps1

Then, in Vortex: press Deploy (these are new files, so the hardlinks do not exist
yet), and enable `Chemistry.esp` after `Rapport.esp`. Chemistry logs into
`Rapport.log`, prefixed `chemistry:`.

What Rapport has already proven in game, which Chemistry inherits for free:

| | |
| --- | --- |
| Candidate selection | 20-30 candidates from ~50 loaded actors, 0.02 ms a pass |
| Adults only | Engine child check verified in Diamond City, plus a race allow-list that fails closed |
| Never a quest actor | Alias instances with running packages are skipped |
| Pair scoring | Proximity, shared faction, indoors, night, onlookers |
| Scenes end to end | Tree chosen at StartScene, faces following the act, the climax face on the frame the animation reaches it, aftermath in the place it belongs |
