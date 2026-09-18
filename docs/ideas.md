# Ideas

A place to put them before they are decisions. Nothing here is settled; a line moves into
DESIGN.md only when it has been chosen, and into Rapport only if a second mod would want it.

## Owner's

- (2026-09-18) Persistent aftermath: visible cum for a while after a scene, on the body part
  it landed on. Belongs to Rapport rather than here — Player Proposals wants it too — but
  Chemistry decides when autonomy scenes produce it. AAF's installed overlay sets on the
  reference setup: Belly, Anal, Breasts, DP, Back, M_Back, M_Chest (+ _Mutant). There is no
  face set in those packs; one would have to come from an overlay mod that provides it.
  Checked. CumOverlays v1.4 is two things bundled: assets (57 LooksMenu templates, the textures
  BA2, the esp LooksMenu keys against, and the AAF overlay sets) and logic (two scripts and an MCM
  page). The assets cannot be replaced without commissioning art; the logic can. So it becomes a
  resource dependency like an animation pack, and Rapport drives the sets.

  AAF already supports a duration on an overlay group in XML, so "visible for N time" needs no
  code. What it cannot do is survive a save, a reload, or the game closing mid-timer -- an overlay
  stranded that way stays on the actor forever. Persistence in game time is Rapport's part, and the
  reason this belongs in the framework rather than here.

  No face or mouth template exists in those 57, so cum on the face is not possible with the assets
  on hand.

## Open questions

- How often should a settlement produce a scene? Frequency is the thing that makes an
  autonomy mod feel cheap, and the design's line is believability over frequency.
- Should the player ever walk in on one, or should the privacy scoring make that rare?
- Do repeat pairings matter — do two NPCs who chose each other once become likelier, and
  does that read as a relationship or as a rut?
