# Contributing to Chemistry

Chemistry is deliberately small: one Papyrus script and one generated ESP. Most contributions that
feel like they belong here belong in [Rapport](../fo4-rapport) instead, and the test for that is the
first section below.

## The one rule that decides where code goes

> **If something here starts looking useful to another mod, it is in the wrong repository.**

Chemistry is **policy**: whether a pair Rapport published is worth acting on, and when. Everything
else is the framework's, because **Player Proposals** is the next addon and will want all of it.

Concretely, none of this belongs here and none of it should be reimplemented here:

- Actor enumeration, filtering, the child and race checks, the quest-actor check.
- The AAF bridge, scene requests, the busy-flag discipline, the scene lifecycle.
- Persistence of any kind: cooldowns, refusals, per-pair history, the `need` float.
- Faces, the aftermath, the tree catalogue, the spot finder.

If you need a fact Rapport does not publish, **add it to Rapport's addon API** rather than measuring
it here. The one exception so far is cell ownership (`C-8`), and the reason is structural: Rapport's
scoring is C++ and CommonLibF4 leaves `TESObjectCELL` forward-declared, so it is only reachable from
Papyrus. Rapport reports what it can see; the addon adds what only Papyrus can reach. That is a
line, not a loophole.

## Before you change a number

Every tunable in `Autonomy.psc` implements a decision recorded in `DESIGN.md` as `C-1` to `C-8`,
with the reason. Read the one you are about to change. Several of them are not free choices:

- **`iCrowdTolerance` must equal Rapport's `observerTolerance`** in `scoring.json`. If they ever
  disagree, one layer calls a pair private while the other calls it crowded — which is exactly the
  contradiction the first version shipped with, and the log caught it inside two scenes.
- **`fBondCap` exists to prevent a rut**, not to be tidy. It is what separates "these two have
  something" from "these two are the only two".
- **`fCooldownHours` is per actor, not per pair**, and that is the stricter reading on purpose.

If a change makes one of those decisions wrong, amend `DESIGN.md` — do not quietly edit the number
and leave the reasoning describing something else.

## The rules inherited from Rapport

These are Papyrus facts, not preferences, and they cost that project real debugging time:

**One timer, ever.** `kPollTimer = 1`, cancelled before it is started, and never a second id in this
script. Rapport's bridge polled 17 times and stopped at the exact poll that called `StartTimer` with
a second id; both places using a second id aborted at that statement.

**A failed `as` cast assigns None.** Land that on a loop counter and the loop never increments. One
such bug in Rapport wrote 845,998 lines and 912 MB.

**Decompiled base sources carry no default argument values**, so pass every argument explicitly.
That is a compile error rather than a silent one, but it is why the style here looks verbose.

**Read form ids, not actors.** The pointers behind a scored pair are valid only on the tick that
produced them, and Chemistry reads later on its own timer. A stale id resolves to `None` and is
skipped; a stale pointer is a crash in this mod.

**Check `Busy()` first and skip the whole pass.** `RequestScene` declines while a scene is running
anyway — but by then you have read every candidate, scored them, and printed a decision you cannot
use. A scene lasts minutes and a poll lasts seconds.

## The log is a feature

Nothing about this mod is visible on screen. **A settlement where nothing happens looks exactly like
a settlement where the logic is broken.** So:

> Any decision must be reconstructable from the log alone — what was on offer, what each pair was
> worth, why each was passed over, and what the winner was chosen for.

That is not decoration and it is not optional for new policy. `C-6` was found and fixed because the
log disagreed with Rapport's own crowd tolerance, in writing, within two scenes.

Keep level 2 useful: the question "why is it never choosing anybody" needs the passes where it chose
nobody, and a log that only speaks when it acts cannot answer it.

Chemistry writes into `Rapport.log`, prefixed `chemistry:`. Do not add a second log file.

## Save health, for whoever adds state here

`Rapport:Core.SetNeed` **creates** a record for that actor, and a record with no scene and no
refusal has no timestamp to age against — it can only be collected by being empty. So write `need`
for actors that matter, not for every candidate you look at, and set it to `0.0` when done.

Chemistry currently writes none at all, which is the cheapest correct answer. If you change that,
say why in `DESIGN.md`.

## Building and testing

```
python tools/make_esp.py data/Chemistry.esp
scripts/build-papyrus.ps1
scripts/deploy-dev.ps1
```

Neither the ESP nor the compiled scripts are committed. Both are generated and both are verifiable
from source; committing either would mean a checkout could disagree with its own sources and nothing
would say which was right.

`scripts/*.ps1` take their paths as parameters. **Do not commit your own machine's paths as the
defaults.**

Leave Papyrus logging on while developing. Rapport's `debug.json` drives it for the whole stack.

## When you change something

- A decision goes into `DESIGN.md` as a new `C-#` with its reason, not as an edited old one.
- An idea that is not yet a decision goes into `docs/ideas.md`. A line moves between the two only
  when it has been chosen.
- If it changes what is verified in game, update `docs/FEATURES.md`. That distinction rots fastest.

## Commit messages

Say what changed and why, in the voice of the thing that was wrong. The existing history is the
style guide: *"Stop asking the NPC who always says no"*, *"Privacy is the same number Rapport
already uses"*, *"Say why nothing happened"*.
