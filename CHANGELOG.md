# Changelog

## Unreleased

- **Your lover is spoken for.** Someone who is your lover through Overture now pays the same
  faithfulness cost as a married NPC when Chemistry pairs them with anyone else, and if it happens
  anyway it's recorded as an affair. On by default, with a switch in MCM (Personas). Needs Rapport
  0.2.1; with Rapport 0.2.0 nobody is anyone's lover and nothing changes.

## 0.2.0

**Requires Rapport 0.2.0.** Chemistry checks it on load. Against an older Rapport it stays
idle, logs one line per load, and leaves Rapport's own trigger alone. Once Rapport is updated,
the next load brings autonomy back.

- **Relationships decide more.** A pair's bond from Rapport's store adds up to ±0.45, and
  the game's own relationships count before a first scene: a married couple starts close,
  and enemies pay.
- **Personas.** Kindred spirits pair a little more readily, and romantic and vulgar clash.
  In a crowd, vulgar types like an audience and reticent ones hold back. In the open, a
  vulgar one doesn't take it slow.
- **Faithfulness.** Someone married or courting pays for straying, in proportion to how
  faithful they are. When they stray anyway, it is recorded as an affair.
- **MCM menu.** Every tunable, with an on/off switch for autonomy. MCM stays optional.
- **Narrated.** With Rapport's Narrator, every scene Chemistry starts says why, including
  Chemistry's own share of the score.
- **Fixes.**
  - If MCM is installed but Chemistry's settings are missing, the built-in defaults now apply.
    Autonomy used to switch itself off silently.
  - The poll interval can't go below 20 seconds (a setting of 5-15 now reads as 20), because
    a pass can take seconds.
  - A pair is never judged from two different candidate lists read half before and half
    after Rapport refreshed them.
  - After a restart, Rapport's built-in trigger no longer runs alongside Chemistry.
  - A pair can no longer be judged with another pair's crowd count.

## 0.1.0

First release.

NPC autonomy for [Rapport](https://www.nexusmods.com/fallout4/mods/109219): adult NPCs
occasionally start AAF scenes with each other, because they chose to rather than because a
perk was sprayed on them.

Rare and per actor (24 game hours each, not per pair), no global rate and no quota, couples
can emerge but are capped, and whose place it is decides how unhurried the scene gets. A
crowd is prohibitive; two onlookers cost nothing. It stops asking the NPC who always says
no, and every pass explains in the log what it saw and what it decided.
