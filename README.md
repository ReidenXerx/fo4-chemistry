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

Not started. Rapport does not yet expose a public API for addons, and until it does there is
nothing for Chemistry to sit on. Rapport currently carries a temporary stand-in for this
decision inside its scheduler, marked as such, which moves here when the API exists.

What Rapport has already proven in game, which Chemistry inherits for free:

| | |
| --- | --- |
| Candidate selection | 20-30 candidates from ~50 loaded actors, 0.02 ms a pass |
| Adults only | Engine child check verified in Diamond City, plus a race allow-list that fails closed |
| Never a quest actor | Alias instances with running packages are skipped |
| Pair scoring | Proximity, shared faction, indoors, night, onlookers, player presence |
| A real scene | Geneva and a Diamond City guard, 2026-09-18 |
