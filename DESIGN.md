# Design

Decisions, with the reason. A line only appears here once it has been chosen; the
unchosen ones live in `docs/ideas.md`.

Chemistry is **policy**. Rapport enumerates, filters, scores, starts, stages, keeps
the faces and applies the aftermath. Anything a second mod would also want belongs
there, because Player Proposals is next and will want all of it.

## C-1 - Chemistry selects, Rapport scores (2026-09-19)

Rapport publishes every viable pair each pass with the raw measurements behind its
own ranking: distance, observers, interior, night, shared faction, and both actors
as form ids. Chemistry reads that and decides.

It does not re-implement any of the measuring, and it must not. `PairSignals` in
Rapport says why in its own comment: "an addon decides what to do with these, the
framework only says what is true of the two actors", and `minimumScore` is
documented there as what an addon would need, reported and never enforced.

Form ids rather than actors, because the pointers behind a scored pair are valid
only on the tick that produced them and Chemistry reads later, on its own timer.
A stale id resolves to None and is skipped; a stale pointer would be a crash.

`Rapport:Core.TakeOverDecisions("Chemistry")` is called on every `Connect`, which
retires Rapport's own stand-in decision AND its 24-hour cooldown filter - that
filter runs before ranking, so leaving it on would hide resting pairs from the
policy that is supposed to judge them.

## C-2 - Rare, and per ACTOR (2026-09-19)

Owner's decision. No global rate and no settlement quota: a busy settlement
produces more than an empty one purely because it contains more pairs.

The rest is per actor, not per pair, and that is the stricter reading -
deliberately. Per-pair alone would let one settler have a scene with B, then C,
then D in an evening, which reads as a mod rather than as people. 24 game hours,
`fCooldownHours`.

## C-3 - A pair with history is worth a little more (2026-09-19)

Owner's decision: mildly likelier, so couples emerge over a playthrough. +0.15 per
previous scene together, capped at +0.45, against a bar of 0.90.

Capped because `docs/ideas.md` names the failure: a rut, where the same two
monopolise a settlement. The cap is what separates "these two have something" from
"these two are the only two".

This needs `PairSceneCount`, which is a per-pair table in Rapport's co-save.
`LastPartner` cannot support it - it holds only the MOST RECENT partner, so the
memory decays the moment either of them is with somebody else, which is exactly
when a settlement becomes interesting.

## C-4 - The player is not a factor (2026-09-19)

Owner's decision. Chemistry never consults `CandidatePlayerNear`, and Rapport's own
`playerNear` weight is 0.0 in `scoring.json`. The signal is still measured and still
published, so this is a decision rather than a missing capability.

A scene may therefore start in front of the player. That is intended.

## C-5 - A crowd is prohibitive; a couple of onlookers is nothing (inherited)

Already Rapport's, verified rather than assumed: the penalty is
0.2 * (observers - 2)^1.5, and the pair exclude themselves from the count. So zero
to two onlookers cost nothing at all, three costs 0.20, five costs 1.04 and eight
costs 2.94, against a best-possible score near 2.65 and a bar of 0.90. Non-linear
and forgiving, which is what was wanted.

Chemistry adds nothing here. It reads `CandidateScore`, which already includes it.

## UNCONFIRMED - which scenario fits where

`ScenarioFor` is an ASSUMPTION, flagged here as the first thing to check:

| where they are | scenario |
| --- | --- |
| indoors, nobody watching | `athome` - five stages, unhurried, ends in a climax |
| one onlooker or fewer | `tender` - three stages, slow |
| anywhere busier | `quickie` - one stage, no guaranteed ending |

The reasoning is that privacy buys time: somewhere private and empty is where two
people would take their time, and a corner of a market is where they would not. It
follows the same "believability over frequency" line as the rest, but nobody has
chosen it and it has never been watched in game.

## What is deliberately NOT here

- Actor enumeration, filtering, the child and race checks, the quest-actor check.
- The AAF bridge, scene requests, the busy-flag discipline, the scene lifecycle.
- Persistence of any kind: cooldowns, refusals, per-pair history, the `need` float.
- Faces, the aftermath, the tree catalogue, the spot finder.

All of it is Rapport's. If something in this repository starts looking useful to
another mod, it is in the wrong repository.

## Save health, for whoever adds state here

`Rapport:Core.SetNeed` CREATES a record for that actor, and a record with no scene
and no refusal has no timestamp to age against - it can only be collected by being
empty. So write `need` for actors that matter, not for every candidate you look at,
and set it to 0.0 when done. Chemistry currently writes none at all.
