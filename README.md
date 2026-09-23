# Chemistry

NPC autonomy for Fallout 4: adult NPCs occasionally start AAF scenes with each other, because they
chose to rather than because a perk was sprayed on them.

**Requires [Rapport](https://www.nexusmods.com/fallout4/mods/109219) 0.2.0 or newer.** Chemistry decides; Rapport does.

## What it is

One Papyrus script and one generated ESP, and that is the whole mod. Every pass, Rapport publishes
the pairs it can see with the raw measurements behind its own ranking; Chemistry reads that list and
either asks for one scene or explains in the log why it asked for none.

| | |
| --- | --- |
| **Rare, and per actor** | 24 game hours per actor, not per pair. Per-pair alone would let one settler have a scene with B, then C, then D in an evening, which reads as a mod rather than as people. |
| **No global rate, no quota** | A busy settlement produces more than an empty one because it contains more pairs. That is the intended shape. |
| **Couples can emerge** | A pair with history is mildly likelier — and capped, because the failure it is guarding against is a rut where the same two monopolise a settlement. |
| **Whose place it is** | Their own home earns the long, unhurried story whatever the room count. Somebody walking through your house is not an audience in a market. |
| **A crowd is prohibitive; two onlookers are nothing** | The same tolerance Rapport already uses, deliberately the same number, because one layer calling a pair private while the other calls it crowded is the contradiction this shipped with once. |
| **It stops asking the NPC who always says no** | An escalating backoff on refusals. AAF leaves a busy flag on an NPC for the rest of the save if a request dies badly, and one such NPC scores top of the list and burns a request every time. |
| **Bond and persona** | A pair's bond in Rapport's relationship store counts, married couples before their first scene too. Personas bend who pairs and which story plays (C-8). |
| **Your lover is spoken for** | Someone who is your lover through Overture pays the same faithfulness cost as a married NPC with anyone else, and straying is recorded as an affair. A switch in MCM (with Rapport 0.2.1). |
| **Your own scene comes first** | While Rapport holds its one scene slot for a scene you asked for, Chemistry waits (with Rapport 0.2.1). |
| **A log you can reconstruct any decision from** | Nothing about this mod is visible on screen: a settlement where nothing happens looks exactly like a settlement where the logic is broken. |

`DESIGN.md` has the reasoning, `C-1` to `C-8`. `docs/FEATURES.md` is the audit, including what is
built but not yet verified in a real game.

## What belongs here

The policy. When a pair is worth acting on, how often, what a settlement should feel like, what the
player should and should not walk in on.

## What does not belong here

Anything a second mod would also need. Actor enumeration and filtering, the AAF bridge, scene
requests, the busy-flag discipline, persistent attraction, cooldowns, refusal memory, the spot
finder, the co-save — all of that is Rapport's, and Player Proposals will want every one of them
too.

**If something here starts looking useful to another mod, it is in the wrong repository.**

## Requirements

| | |
| --- | --- |
| Rapport | The framework, and everything it requires — Fallout 4 1.10.163, F4SE 0.6.23, AAF 1.7.4.1. |
| Load order | `Chemistry.esp` **after** `Rapport.esp`. |

Chemistry needs no assets of its own, no textures and no animations. **MCM is optional**: with it,
every tunable is a setting on two pages (*Autonomy* and *Relationships*), read on every poll so a
change applies within 30 seconds. Without it, the defaults in `Autonomy.psc`'s `Defaults()` apply,
and `scripts/build-mcm.py` generates the menu's defaults from that same function. Crowd tolerance
lives on Rapport's page, because both mods use that one number.

## Install

```
python tools/make_esp.py data/Chemistry.esp
scripts/build-papyrus.ps1
scripts/deploy-dev.ps1
```

Neither the ESP nor the compiled scripts are committed — both are generated and both are verifiable
from source, and committing either would mean a checkout could disagree with its own sources with
nothing to say which was right.

Then enable `Chemistry.esp` after `Rapport.esp`. Chemistry logs into **`Rapport.log`**, prefixed
`chemistry:`, rather than into a second file nobody thinks to read next to the first.

`scripts/build-papyrus.ps1` and `scripts/deploy-dev.ps1` take their paths as parameters; the
defaults are the author's machine and you will want your own.

## How this relates to Rapport

```
Rapport   (framework)   enumeration, filtering, scoring, the AAF bridge, scene lifecycle,
                        faces, aftermath, the co-save, the addon API
    ^
    |  Core.Candidate* / Core.CanRun / Core.RequestScene / Core.TakeOverDecisions
    |
Chemistry (this)        the policy — which pair, how often, what story fits where
```

Chemistry calls `Rapport:Core.TakeOverDecisions("Chemistry")` on every connect. That retires
Rapport's own stand-in decision — it ships one so the framework can be tested with no addon
installed — **and** its 24-hour cooldown filter, which runs before ranking and would otherwise hide
resting pairs from the policy that is supposed to judge them. From that moment, enforcing a cooldown
is Chemistry's job.

What Rapport has already proven in game, which Chemistry inherits for free:

| | |
| --- | --- |
| Candidate selection | 20–30 candidates from ~50 loaded actors, 0.02 ms a pass |
| Adults only | Engine child check verified in Diamond City, plus a race allow-list that fails closed |
| Never a quest actor | Alias instances with running packages are skipped |
| Pair scoring | Proximity, shared faction, indoors, night, onlookers |
| Scenes end to end | Tree chosen at `StartScene`, faces following the act, the climax face on the frame the animation reaches it, aftermath in the place it belongs |

## Credits

Chemistry ships no assets and drives nothing directly. It talks to Rapport and nothing else.

- **Rapport** — the framework. Same author.
- **AAF** — Dagobaking, reached only through Rapport.
- **F4SE** — ianpatt, behippo, purple lunchbox.

## Licence

**GNU General Public License v3.0** — see [`LICENSE`](LICENSE).

In short: use it, study it, change it, share it. Anything you distribute that is derived from this
must carry the same freedoms. `extern/CommonLibF4` is a submodule rather than vendored source and is
governed by its own terms.

## Not decided yet

Deliberately left to the owner rather than settled in this file:

- **Repository visibility**, and where — if anywhere — this is published.
- **Naming and branding.**
- **Adult-content gating and warnings**, and how they relate to Rapport's.

And three questions from `docs/ideas.md` that are still open on the design itself: how often a
settlement should produce a scene, whether the player should ever walk in on one, and whether repeat
pairings read as a relationship or as a rut.
