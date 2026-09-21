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

**Revised 2026-09-21 (Rapport R-13, owner poll: "C-3 reads the store").** The scene count is
retired. The bonus is now Rapport's bond for the pair, one for one, capped at +/-0.45
(`BondBonus`). A scene moves the bond 15% of the remaining way to +1, so the first three add
+0.15, +0.28 and +0.39: the old curve, flattening sooner. The cap and the rut argument are
unchanged. Two things are new:

- **The engine's relationship counts before the first scene.** `Rapport:Relations.BondBetween`
  reads the stored bond once a pair has one, and before that what the engine's rank and
  marriage WOULD seed, without writing a record. A married couple starts at +0.80, so at the
  cap. Friends start at +0.15.
- **Enemies are penalised symmetrically,** down to -0.45.

Blood relatives are NOT refused (Rapport R-14, owner). The store flags them for a later
attitude layer to judge.

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

## C-6 - privacy is the same number Rapport already uses (2026-09-20)

Owner's decision, taken after watching it get this wrong. Which story fits where:

| where they are | scenario |
| --- | --- |
| indoors, at most 2 watching | `athome` - five stages, unhurried, ends in a climax |
| out in the open, at most 2 watching | `tender` - three stages, slow |
| more than 2 watching | `quickie` - one stage, no guaranteed ending |

The first version used 0 and 1, and the log showed it wrong inside two scenes. It
chose `quickie` for a pair with two onlookers, while Rapport scored those same two
onlookers at **exactly zero cost** -- `observerTolerance` is 2, and the crowd penalty
does not begin until the third. One layer was calling two watchers nothing and the
other was calling them too busy for anything long.

Owner settled it on the side of Rapport's tolerance: *"we tolerate 2 people to engage
at home indoors - it fits the post-apocalyptic vibe"*. In this world nobody is shy,
and two people nearby is not a crowd.

So `iCrowdTolerance` in Chemistry is deliberately the same number as
`observerTolerance` in Rapport's `scoring.json`. If those two ever disagree, one layer
calls a pair private while the other calls it crowded, which is the contradiction that
shipped the first time.

Retroactively: both of this morning's scenes would have been `tender` rather than
`quickie`.

## C-7 - stop asking the NPC who always says no (2026-09-20)

AAF silently refuses an actor carrying its busy keywords, and a request that died
without cleaning up leaves that flag on an NPC for the rest of the save. One is in
that state on the reference install -- not from anything Rapport did -- and because he
stands close to somebody he scores top of the list and burned the first request of the
session.

An escalating backoff on refusals: `fRefusalBackoffHours` per refusal, capped at
`fRefusalBackoffCap`. Two game hours after one, four after two, to a cap of two days.

Escalating rather than flat because the two cases want opposite answers: a one-off
refusal should cost almost nothing, and an NPC who is simply broken should be dropped
for good. It uses both of Rapport's facts -- `RefusalCount` and `HoursSinceRefusal` --
because either alone is wrong. The count with no recency avoids somebody forever over
one bad afternoon; recency alone cannot tell bad luck from a permanent flag.


## C-8 - personas steer pairing and the story (owner poll, 2026-09-21)

Rapport R-13 says personas drive Chemistry. The owner chose "scenario + pairing" and approved
these rules as proposed. Each NPC's persona is Rapport's: derived from the form id, or pinned in
`personas.json` (Ivy is pinned vulgar).

| Pairing (added to the score; the bar is 0.90) | |
| --- | --- |
| same persona | +0.10, kindred spirits |
| romantic with vulgar | -0.10, they clash |
| crowd (more than `iCrowdTolerance` watching), per vulgar member | +0.15, likes an audience |
| crowd, per reticent member | -0.30, shy of crowds |
| mercantile | nothing; its flavour is in the barks |

Scenario: C-6's place rule stays the base. The one change: out in the open and uncrowded, where
C-6 says `tender`, a pair with a vulgar member gets `quickie`. Their own place, a private room
and a crowd are unchanged.

Bond (C-3) and place bonuses are unchanged. `fPersonaMax` (0.40) bounds the early exit in
`Consider`, so it has to stay at least the largest total the rules above can reach.
## C-8 - whose place is it (2026-09-20)

Owner: knowing WHICH indoors is the immersive lever. It is, and only one form of it
is cheaply reachable.

What is not: the location's TYPE. `Location.HasKeyword` needs an actual Keyword
form and Papyrus has no lookup by name, so it would take hardcoded vanilla form ids;
`Cell` has no name accessor at all; and CommonLibF4 leaves both `BGSLocation` and
`TESObjectCELL` forward-declared, so the plugin cannot read either without
reverse-engineered layouts. All three checked rather than assumed.

What is: **whose** place it is. `Cell.GetActorOwner()` and `GetFactionOwner()` are
one call each, need nothing hardcoded, and say something better than a type does --
*these two are in his house* rather than *this is a dwelling*.

    2  one of them owns this cell      +0.45 and always "athome"
    1  their faction owns it           +0.20
    0  nobody's, somebody else's, outdoors

Their own place earns the long story **whatever the room count**. Somebody walking
through your house is not an audience in a market, and refusing to treat those alike
is the entire point of knowing whose place it is.

Added ON TOP of Rapport's indoor bonus rather than replacing it. Owner asked for it
"instead of the usual indoor bonus"; the effect is the same either way, and
subtracting would mean hardcoding a copy of Rapport's `interior` weight here, where
it would silently rot the moment somebody edited `scoring.json`.

**This has to live in Chemistry.** Rapport's scoring is C++ and cannot see cell
ownership at all. It is the first policy input the framework is structurally unable
to measure, which is a reasonable line: Rapport reports what it can see, and the
addon adds what only Papyrus can reach.

Asked for INTERIOR pairs only. An unowned exterior cell says nothing, and asking
would cost several native calls for every actor of every pair on every pass to learn
it. Worked out once per pass into the snapshot, because the decision and the table
both need it and computing it twice is how they come to disagree.

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

## C-9 - Faithfulness is a trait, and straying is recorded (owner, 2026-09-22)

The owner's words, answering how much being partnered elsewhere should cost: *"make it random
persistent value per npc; it will be in future related to 'bad things' if character cheating on
partner"*.

Rapport derives each NPC's faithfulness (0 to 1) from the form id, the same way it derives personas:
stable forever, on every machine, and free to save. Chemistry charges `fFaithWeight` (0.60) times it,
for each member who is married or courting someone who is not in this pair. A partner never pays for
their own partner. When a pair strays anyway, Chemistry records it as an affair in Rapport's store
(`NoteAffair`), for the attitude layer to judge.

## C-10 - Chemistry tells the Narrator its share (2026-09-22)

Before every request, Chemistry reports its own parts of the score to Rapport's Narrator: bond, own
place or faction place, personas, and "spoken for". It also reports a zero-valued "couple" marker,
because the store only learns two people are married when their first scene starts. When the best
pair of a pass falls within `fNearMissMargin` of the bar, Chemistry says why it didn't happen, as a
clause with no names; Rapport rate-limits those lines.

