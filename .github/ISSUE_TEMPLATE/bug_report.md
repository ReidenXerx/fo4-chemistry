---
name: Bug report
about: Something Chemistry decided, or did not decide, in game
title: ''
labels: bug
assignees: ''
---

<!--
FIRST: which half is it?

Chemistry decides WHICH PAIR and WHEN. Rapport does everything else — starting the scene, the
faces, the aftermath, the co-save, talking to AAF. If the complaint is about how a scene looked or
how it ended, it is a Rapport issue and belongs in that repository.

Chemistry issues look like: nothing ever happens; the same two NPCs every time; it chose a quickie
in somebody's bedroom; it picked an NPC who never actually does anything.

SECOND: read the log. Chemistry writes into Rapport.log, prefixed "chemistry:", and it is built so
that any decision can be reconstructed from it — what was on offer, what each pair was worth, and
why each was passed over. Set the verbosity to 2 and let it run a few passes before reporting
"it never chooses anybody": level 2 is the setting that prints the passes where it chose nobody.
-->

## What happened

<!-- One or two sentences. What you saw, not what you think caused it. -->

## What you expected instead

## Rapport.log  (REQUIRED)

<!--
ATTACH THE FILE — Documents/My Games/Fallout4/F4SE/Rapport.log.

Chemistry's lines are prefixed "chemistry:", but do not extract only those: the reason it made a
decision is usually in Rapport's own lines just above — the candidate count, the scoring weights, or
AAF refusing somebody.

Please include at least a few full passes, and turn the verbosity up to 2 first if the complaint is
that nothing happens.

BEFORE YOU ATTACH: the log contains file paths from your machine, which usually include your Windows
user name. Check it and redact if you would rather not share that.
-->

## Runtime inventory  (REQUIRED)

<!-- Copy from the log rather than from memory. -->

| | |
| --- | --- |
| Chemistry version | <!-- or the commit you built from --> |
| Rapport version | <!-- the `Rapport vX.Y.Z` line at the top of the log --> |
| Did Chemistry take over? | <!-- the log says so when TakeOverDecisions is called. If that line is missing, Rapport is still making its own stand-in decisions and that explains a lot of odd behaviour --> |
| Load order | <!-- is Chemistry.esp AFTER Rapport.esp? --> |
| Fallout 4 version | <!-- 1.10.163 only --> |
| Game store | <!-- Steam / GOG / Epic --> |
| F4SE version | <!-- and please attach f4se.log too --> |
| AAF version | |
| Animation packs installed | <!-- names are enough --> |
| Approximate plugin count | |
| Mod manager | <!-- Vortex / MO2 / manual --> |

## The tunables you changed

<!-- They are AutoReadOnly properties in papyrus/Chemistry/Autonomy.psc rather than an ini, so this
     only applies if you built your own. List what you changed from the defaults.

     Note that iCrowdTolerance is not a free choice: it must match observerTolerance in Rapport's
     scoring.json, or one layer calls a pair private while the other calls it crowded. -->

## If nothing ever happens

<!-- Fill this in only for that symptom. Work down the list — the log answers every one of these. -->

- How many candidates does Rapport report per pass:
- How many pairs does Chemistry see (`CandidateCount`):
- What score does the best pair get, against the bar of 0.90:
- Are they being skipped for the cooldown, the crowd, or a refusal backoff:
- Does the log show `Busy()` returning true — i.e. a scene that never ended:

## Anything else
