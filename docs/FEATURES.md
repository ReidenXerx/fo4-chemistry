# Features — what Chemistry decides, why, and how we know

Chemistry is small on purpose. It is one Papyrus script and one generated ESP, and everything it
does is **policy**: which of the pairs Rapport publishes is worth acting on, and when.

The decisions are in `DESIGN.md` as `C-1` to `C-8`, with the reason for each. This file is the
capability list and the evidence behind it.

## How to read the evidence column

| Tier | What it means |
| --- | --- |
| **VERIFIED IN GAME** | Somebody watched it happen, or a log from a real session records it. Named. |
| **BUILT, NOT VERIFIED IN GAME** | The code exists and compiles. Nothing recorded it running. Not a claim that it is broken — a claim that nobody has looked. |
| **INHERITED** | Rapport does it and Chemistry relies on it. The evidence is in `fo4-rapport/docs/FEATURES.md`. |

A note on the README: it still says "First version written, never run." That is out of date. `C-6`
and `C-7` were both settled by reading Chemistry's own log from real sessions — `C-6` by watching it
choose `quickie` for a pair Rapport scored at zero crowd cost, twice.

---

## 1. What it actually does

### Reads Rapport's published pairs and picks one, or none — VERIFIED IN GAME

**What.** Every `fPollSeconds` (30), Chemistry walks Rapport's candidate list from best-scoring
down, applies its own filters, and either asks for one scene or explains why it asked for none.
`papyrus/Chemistry/Autonomy.psc`.

**Why it does not re-measure anything.** Rapport enumerates the loaded actors, drops the children,
the wrong races, the quest actors with running packages and the hostiles, ranks every remaining pair
and publishes the raw measurements behind its own ranking. None of that is policy, and
reimplementing any of it here would mean two mods scanning the same actors and disagreeing.
`PairSignals` says so in its own comment in Rapport's source: *"an addon decides what to do with
these, the framework only says what is true of the two actors"* (`C-1`).

**Why form ids, not actors.** The pointers behind a scored pair are valid only on the tick that
produced them, and Chemistry reads later on its own timer. A stale id resolves to `None` and is
skipped; a stale pointer would be a crash (`C-1`).

### Stands Rapport's own decision down — VERIFIED IN GAME

`Rapport:Core.TakeOverDecisions("Chemistry")` on every `Connect`. Rapport ships a stand-in decision
so the framework can be tested with no addon installed; two things deciding means two mods reserving
the same actors.

It retires Rapport's 24-hour cooldown filter as well, and that half matters: **that filter runs
before ranking**, so leaving it on would hide resting pairs from the policy that is supposed to
judge them. Once it is called, enforcing a cooldown is Chemistry's job (`C-1`).

### One timer, and that is not a preference — BUILT (inherited as a rule)

`kPollTimer = 1`, cancelled before it is started, and never a second id in this script. Rapport's
bridge learned this the hard way: its poll ran 17 times and stopped at the exact poll that called
`StartTimer` with a second id. Both places using a second id aborted at that statement.

**Corrected 2026-09-23:** Rapport's own later runs put that failure on an AAF call that never
returns, not on the second id (its `docs/two-lifetimes.md`: run 2 removed every `StartTimer` and
failed the same way). `OnTimer` runs one at a time per script, so one stuck handler starves every
timer on it. Chemistry calls no AAF function at all, so the rule it inherits is really "never stall
a timer's stack"; one timer stays, as a simplicity.

### Checks `Busy()` before it reasons — VERIFIED IN GAME

**What.** If a scene of ours is already running, the pass ends immediately.

**Why.** `RequestScene` declines while busy anyway — but by then Chemistry has read every candidate,
scored them, and printed a decision it cannot use. A scene lasts minutes and a poll lasts seconds.
(Commit `3390ec7`, "Do not decide while a scene is already playing".)

### Sits out while the slot is held for the player — BUILT, NOT VERIFIED IN GAME

**What.** While Rapport holds its one scene slot for the player's own request
(`Rapport:Core.PlayerHoldsSlot()`, Rapport 0.2.1), the pass ends as it does when a scene is running.

**Why.** The owner's priority lane (Overture O-16): a deliberate player request outranks autonomy, and
every request Chemistry could make is refused while the hold stands anyway. Counted with the busy
passes in the tally. Rapport also re-checks at the door that nobody picked is talking to the player
(its R-17), so the NPC the player is approaching is never walked off mid-sentence.

---

## 2. The policy

### Per-actor cooldown, 24 game hours — VERIFIED IN GAME

**What.** `fCooldownHours`. Per **actor**, not per pair.

**Why the stricter reading, deliberately.** Per-pair alone would let one settler have a scene with
B, then C, then D in an evening, which reads as a mod rather than as people (`C-2`).

**And no global rate and no settlement quota.** A busy settlement produces more than an empty one
purely because it contains more pairs. That is the intended shape — owner's decision.

### A pair with history is worth a little more — BUILT, NOT VERIFIED IN GAME

**What.** `+0.15` per previous scene together, capped at `+0.45`, against a bar of `0.90`
(`fRepeatBonus`, `fRepeatCap`, `fMinimumScore`).

**Why capped.** `docs/ideas.md` names the failure it is guarding against: a rut, where the same two
monopolise a settlement. The cap is what separates "these two have something" from "these two are
the only two" (`C-3`).

**Why it needs Rapport's pair table.** `LastPartner` holds only the *most recent* partner, so the
memory decays the moment either of them is with somebody else — which is exactly when a settlement
becomes interesting. `PairSceneCount` is a per-pair table in Rapport's co-save, added for this.

Nothing in the logs records a repeat pairing actually firing; it needs two scenes between the same
two NPCs on one save.

### Whose place it is — BUILT, NOT VERIFIED IN GAME

**What.** For **interior** pairs only, `Cell.GetActorOwner()` and `GetFactionOwner()`:

```
2  one of them owns this cell      +0.45 and always "athome"
1  their faction owns it           +0.20
0  nobody's, somebody else's, outdoors
```

**Why this and not the location's type.** All three alternatives were checked rather than assumed
(`C-8`): `Location.HasKeyword` needs an actual Keyword form and Papyrus has no lookup by name, so it
would take hardcoded vanilla form ids; `Cell` has no name accessor at all; and CommonLibF4 leaves
both `BGSLocation` and `TESObjectCELL` forward-declared, so the plugin cannot read either without
reverse-engineered layouts.

Ownership is one call each, needs nothing hardcoded, and says something better than a type does —
*these two are in his house* rather than *this is a dwelling*.

**Why their own place earns the long story whatever the room count.** Somebody walking through your
house is not an audience in a market, and refusing to treat those alike is the entire point of
knowing whose place it is.

**Why it lives here and not in Rapport.** Rapport's scoring is C++ and structurally cannot see cell
ownership. This is the first policy input the framework is unable to measure, which is a reasonable
line: Rapport reports what it can see, and the addon adds what only Papyrus can reach (`C-8`).

**Why interiors only.** An unowned exterior cell says nothing, and asking would cost several native
calls for every actor of every pair on every pass. It is worked out once per pass into the snapshot,
because the decision and the log table both need it and computing it twice is how they come to
disagree.

### Which story fits where — VERIFIED IN GAME (and corrected there)

| Where they are | Scenario |
| --- | --- |
| indoors, at most 2 watching | `athome` — five stages, unhurried, ends in a climax |
| out in the open, at most 2 watching | `tender` — three stages, slow |
| more than 2 watching | `quickie` — one stage, no guaranteed ending |

**Why `iCrowdTolerance` is 2 and not 0.** This is the one decision the log overturned. The first
version used 0 and 1, and it was wrong inside two scenes: it chose `quickie` for a pair with two
onlookers, while Rapport scored those same two onlookers at **exactly zero cost** — its
`observerTolerance` is 2 and the crowd penalty does not begin until the third. One layer was calling
two watchers nothing and the other was calling them too busy for anything long.

The owner settled it on the side of Rapport's tolerance. `iCrowdTolerance` here is **deliberately
the same number** as `observerTolerance` in Rapport's `scoring.json`: if the two ever disagree, one
layer calls a pair private while the other calls it crowded, which is the contradiction that shipped
the first time (`C-6`).

Retroactively, both of that morning's scenes would have been `tender` rather than `quickie`.

### The player is not a factor — VERIFIED IN GAME (as a decision, not a gap)

Chemistry never consults `CandidatePlayerNear`, and Rapport's own `playerNear` weight is `0.0` in
`scoring.json`. The signal is still measured and still published, so this is a decision rather than
a missing capability. A scene may therefore start in front of the player, and that is intended
(`C-4`).

**Amended by the owner, 2026-09-23 (Overture O-15): the player's LOVER is a factor.** Someone Rapport
says is the player's lover (`AreLovers(npc, player)`, declared by Overture at a bond of 0.75 and a
scene together) counts as spoken for: they pay the faithfulness cost with anyone else, and a scene
anyway is recorded as an affair on that pair. Only the player's lover, and behind the MCM switch
`bLoverSpokenFor` (on). BUILT, NOT VERIFIED IN GAME. The player's presence is still not a factor.

### An escalating refusal backoff — VERIFIED IN GAME (the condition, not the cure)

**What.** `fRefusalBackoffHours` (2) per refusal, capped at `fRefusalBackoffCap` (48). Two game
hours after one refusal, four after two, to a cap of two days.

**Why it exists.** AAF silently refuses an actor carrying its busy keywords, and a request that died
without cleaning up leaves that flag on an NPC **for the rest of the save**. One NPC on the
reference install is in exactly that state — not from anything Rapport did — and because he stands
close to somebody he scores top of the list and burned the first request of the session (`C-7`).

**Why escalating rather than flat.** The two cases want opposite answers: a one-off refusal should
cost almost nothing, and an NPC who is simply broken should be dropped for good.

**Why it uses both facts.** `RefusalCount` and `HoursSinceRefusal` together. The count with no
recency avoids somebody forever over one bad afternoon; recency alone cannot tell bad luck from a
permanent flag.

The condition is verified — it was observed on a real install. The backoff *holding* over two game
days is not recorded anywhere.

### `CanRun` before asking — BUILT, NOT VERIFIED IN GAME

Chemistry asks `Rapport:Core.CanRun(scenario, a, b)` before requesting, and only `-1` is treated as
a refusal — `0` through `3` all play and differ only in how strong a promise Rapport can make about
the ending.

Commit `5b9ce09` ("Ask for the scene before spending three seconds explaining it") moved the request
ahead of the log table for a reason worth keeping: the table is twelve lines of Papyrus string work
and the pair can move while it is being written.

---

## 3. The log

### Any decision must be reconstructable from the log alone — VERIFIED IN GAME

**What.** Up to twenty-four pairs compared against a cooldown, a score, a history bonus and a bar,
with what each was worth and why each was passed over, and what the winner was chosen for. Three
verbosity levels; level 1 prints the full table whenever it **acts** and a tally otherwise.

**Why this is a feature and not decoration.** Nothing about this mod is visible on screen. **A
settlement where nothing happens looks exactly like a settlement where the logic is broken.** That
is the same instrument-not-argument rule Rapport learned from its dead poll, and it is why level 2
exists at all: the question "why is it never choosing anybody" needs the passes where it chose
nobody.

**Evidence that it works.** `C-6` was found by reading it — the log disagreed with Rapport's own
crowd tolerance, and that disagreement is what got fixed. A log that catches your own policy being
wrong within two scenes is doing its job.

Chemistry writes into **`Rapport.log`**, prefixed `chemistry:`, rather than into a second file
nobody thinks to read next to the first.

### One reading of the list per pass — VERIFIED IN GAME

The decision and the report come from the same snapshot (commit `c22f784`). Reading the published
list twice means the table can describe a different world from the one the decision was made in.

---

## 4. Deliberately not here

Not "not done yet" — **structurally somebody else's**, and the reason is the same every time: Player
Proposals is next and will want all of it.

- Actor enumeration, filtering, the child and race checks, the quest-actor check.
- The AAF bridge, scene requests, the busy-flag discipline, the scene lifecycle.
- Persistence of any kind: cooldowns, refusals, per-pair history, the `need` float.
- Faces, the aftermath, the tree catalogue, the spot finder.

The test: **if something here starts looking useful to another mod, it is in the wrong repository.**

### Save health, for whoever adds state here

`Rapport:Core.SetNeed` **creates** a record for that actor, and a record with no scene and no refusal
has no timestamp to age against — it can only be collected by being empty. So write `need` for actors
that matter, not for every candidate you look at, and set it to `0.0` when done.

**Chemistry currently writes none at all**, which is the cheapest correct answer.

---

## 5. Open, from `docs/ideas.md`

Nothing there is settled, and a line moves into `DESIGN.md` only when it has been chosen:

- How often should a settlement produce a scene? Frequency is the thing that makes an autonomy mod
  feel cheap, and the design's line is believability over frequency.
- Should the player ever walk in on one, or should the privacy scoring make that rare? (`C-4`
  answers the *weighting* — the player is not a factor — but not the taste question.)
- Do repeat pairings read as a relationship or as a rut? `C-3`'s cap is a first guess at the answer,
  not a measurement of it.
