Scriptname Chemistry:Autonomy extends Quest
{Chemistry: the whole of it.

 Rapport does the work; this decides. Every pass Rapport enumerates the loaded
 actors, drops the children, the wrong races, the quest actors with running packages
 and the hostiles, ranks every remaining pair and publishes what it measured. None
 of that is here and none of it should be -- Player Proposals will want all of it.

 What is here is policy: whether any of those pairs is worth acting on now.

 And the log, which is not decoration. This mod compares up to twenty-four pairs
 against a cooldown, a score, a history bonus and a bar, then picks one or none.
 Nothing about that is visible on screen: a settlement where nothing happens looks
 exactly like a settlement where the logic is broken. So the rule this file follows
 is that ANY decision must be reconstructable from the log alone -- what was on
 offer, what each was worth, why each was passed over, and what the winner was
 chosen for.

 Style note: the base sources are decompiled and carry no default argument values,
 so every argument is passed explicitly.}

; ONE timer, and that is not a preference.
;
; Rapport's bridge learned this the hard way: its poll ran 17 times and stopped at
; the exact poll that called StartTimer with a SECOND id, and both places using a
; second id aborted at that statement. One id, cancelled before it is started, and
; never a second one in this script.
Int Property kPollTimer = 1 AutoReadOnly

; ---- the tunables -------------------------------------------------------------
;
; Numbers, not decisions. The decisions they implement are in DESIGN.md. Each is a
; player setting in MCM since 2026-09-21: LoadSettings reads them every poll, and
; its Defaults() is THE list of default values - scripts/build-mcm.py generates the
; MCM defaults from it, so the menu and the script cannot disagree. The values on
; the declarations below only matter for the moment before the first poll.

; Off = Chemistry keeps the decision (so Rapport's stand-in does not take it back)
; and starts nothing: a pause, not an uninstall.
Bool bEnabled = True
Float fPollSeconds = 30.0
Float fCooldownHours = 24.0
Float fMinimumScore = 0.90
; Somewhere that belongs to them. Added ON TOP of Rapport's indoor bonus rather
; than replacing it: the indoor weight lives in Rapport's scoring.json, and
; subtracting it from here would hardcode a second copy of somebody else's config.
; The effect is what was asked for either way -- their own place outscores a
; generic interior by this much.
;
; Rapport cannot measure this. Its scoring is C++ and CommonLibF4 leaves
; TESObjectCELL forward-declared, so cell ownership is only reachable from Papyrus,
; which is here.
Float fOwnPlaceBonus = 0.45

; Their faction's place -- a settlement's shared building rather than a bedroom.
; Worth something, worth less than their own.
Float fFactionPlaceBonus = 0.20

; DESIGN C-3, as revised by R-13: history is Rapport's relationship store, not a
; scene count. The bond (-1..+1) adds to the score one for one, capped both ways.
; A scene moves the bond 15% of the way to +1, so three scenes together add
; +0.15, +0.28, +0.39 - the old +0.15-per-scene curve, bent - and the cap is
; still what keeps two people from owning a settlement. What the engine says two
; people ARE counts before they have ever met in a scene: a married couple starts
; at +0.80 and so at the cap, friends at +0.15. Enemies pay the same way down.
Float fBondWeight = 1.0
Float fBondCap = 0.45

; DESIGN C-8 (owner poll 2026-09-21): personas steer pairing. Each NPC's persona is
; Rapport's (derived from the form id, or pinned in personas.json). Mercantile adds
; nothing here - it is flavour, and it lives in the barks.
Float fKindredBonus = 0.10    ; same persona
Float fClashPenalty = 0.10    ; romantic with vulgar
Float fAudienceBonus = 0.15   ; per vulgar member, in a crowd
Float fShyPenalty = 0.30
; Faithfulness (owner, 2026-09-21): each NPC has a persistent random faithfulness,
; 0..1, derived from the form id by Rapport. Pairing with someone who is NOT their
; partner costs this much times it, per partnered member - so a devoted spouse
; almost never strays and a restless one often does. Their own partner is never
; charged. A pair that strays anyway is recorded as an affair in the store.
Float fFaithWeight = 0.60
; A "why nothing happened" line for the Narrator when the best pass came this close.
Float fNearMissMargin = 0.30      ; per reticent member, in a crowd
; The most PersonaBonus can ever add (kindred + two vulgar in a crowd), for the
; early exit in Consider: it must never be smaller than the real maximum.
Float fPersonaMax = 0.40

; Backing off an actor AAF keeps refusing, per refusal, in GAME hours, and the cap.
;
; Not a nicety. AAF silently refuses an actor carrying its busy keywords, and a
; request that died without cleaning up leaves that flag on an NPC for the REST OF
; THE SAVE. Observed on this install first thing: Johnny Friendly is permanently
; stuck, scores top of the list because he stands close to somebody, and burns the
; first request of every session. Rapport benches him for 300 real seconds after a
; failure, which at a 30-second poll means he comes back and wastes another one
; forever.
;
; Escalating rather than flat, because the two cases need different answers: a
; one-off refusal should cost almost nothing, and an NPC who is simply broken should
; be dropped for good. Two hours after one refusal, four after two, and so on to a
; cap of two days.
; How many onlookers still count as privacy. Deliberately the SAME number as
; Rapport's observerTolerance in scoring.json, which forgives the first two entirely
; -- if these two disagree then one layer calls a pair private while the other calls
; it a crowd, which is exactly the contradiction the first version shipped with.
; Now READ from Rapport (ObserverTolerance) every poll instead of kept here: one
; number, so the two can no longer disagree. Set it in Rapport's MCM page.
Int iCrowdTolerance = 2

Float fRefusalBackoffHours = 2.0
Float fRefusalBackoffCap = 48.0

; ---- how much it says ---------------------------------------------------------
;
;   0  only when it acts, plus a tally every iTallyEvery polls
;   1  the full table whenever it ACTS, and the tally otherwise  <- default
;   2  the full table every single pass
;
; One is the useful default because the interesting moments are the ones where a
; choice was made, and those are exactly the ones worth twelve lines. Two is for when
; the question is "why is it never choosing anybody", which needs the passes where it
; chose nobody.
; The most pairs Rapport will publish, and so the size of the snapshot below.
; Rapport keeps 24 for an addon; anything beyond this is ignored rather than read
; from a list that has moved on.
Int Property iMaxPairs = 24 AutoReadOnly

Int iLogLevel = 1
Int Property iTallyEvery = 10 AutoReadOnly

; ---- state, in the save -------------------------------------------------------
Int _polls = 0            ; since the last tally
Int _passes = 0           ; since this load
Int _acted = 0
Int _blockedResting = 0   ; passes where everything eligible was resting
Int _blockedBar = 0       ; passes where the best was under the bar
Int _blockedEmpty = 0     ; passes where Rapport published nothing
Int _blockedBusy = 0      ; passes skipped because a scene was already running


; ONE read of Rapport's list per pass, held here while this pass decides and then
; explains itself.
;
; Rapport republishes on its own twenty-second tick, and printing the table takes
; about three seconds -- so reading the list twice reads two different lists. Seen
; in the log: one table listed "Genevieve + Malcom Latimer" at both 0.92 and 0.32,
; and "Johnny Friendly + Polly" at both 1.02 and 0.82, because a publish landed
; while it was printing. A report that contradicts itself is worse than none.
Int[] _first
Int[] _second
Float[] _score

; Whose place, worked out ONCE per pair per pass and kept.
;
; WhosePlace costs a form lookup, a cell read, an owner read and two base reads for
; every interior pair. The decision needs it and so does the table, and computing it
; twice is both wasteful and a way for the two to disagree if an actor moves between
; them -- which is the bug this snapshot exists to prevent.
Int[] _whose
; Everything else Chemistry reads about a pair, taken in the SAME snapshot as its
; ids. Reading these by index from Rapport later was a race: Rapport republishes
; every 20s, and 2026-09-21 the Codmans' line said "17 watching" - slot 0 of the
; NEXT list, a Drifter pair in another cell - while Rapport had counted 6.
Int[] _observers
Bool[] _interior
Bool[] _night
Bool[] _faction
Bool[] _playerNear
Float[] _distance
Int _held = 0

; ---- lifecycle ----------------------------------------------------------------

Event OnQuestInit()
	Self.Connect()
EndEvent

Event OnInit()
	Self.Connect()
EndEvent

; ---- settings -----------------------------------------------------------------

; THE default values. scripts/build-mcm.py reads the assignments below to write the
; MCM defaults, so change a default HERE and re-run it.
Function Defaults()
	bEnabled = True
	fPollSeconds = 30.0
	fCooldownHours = 24.0
	fMinimumScore = 0.90
	fOwnPlaceBonus = 0.45
	fFactionPlaceBonus = 0.20
	fBondWeight = 1.0
	fBondCap = 0.45
	fKindredBonus = 0.10
	fClashPenalty = 0.10
	fAudienceBonus = 0.15
	fShyPenalty = 0.30
	fFaithWeight = 0.60
	fNearMissMargin = 0.30
	fRefusalBackoffHours = 2.0
	fRefusalBackoffCap = 48.0
	iLogLevel = 1
EndFunction

; Every poll: about fifteen native calls, and a slider takes effect on the next
; poll with no event to register for. Without MCM, the defaults above.
Function LoadSettings()
	Self.Defaults()
	If MCM.IsInstalled()
		bEnabled = MCM.GetModSettingBool("Chemistry", "bEnabled:General")
		fPollSeconds = Self.AtLeast(MCM.GetModSettingFloat("Chemistry", "fPollSeconds:General"), 5.0)
		fCooldownHours = MCM.GetModSettingFloat("Chemistry", "fCooldownHours:General")
		fMinimumScore = MCM.GetModSettingFloat("Chemistry", "fMinimumScore:General")
		fOwnPlaceBonus = MCM.GetModSettingFloat("Chemistry", "fOwnPlaceBonus:Place")
		fFactionPlaceBonus = MCM.GetModSettingFloat("Chemistry", "fFactionPlaceBonus:Place")
		fBondWeight = MCM.GetModSettingFloat("Chemistry", "fBondWeight:Bond")
		fBondCap = MCM.GetModSettingFloat("Chemistry", "fBondCap:Bond")
		fKindredBonus = MCM.GetModSettingFloat("Chemistry", "fKindredBonus:Personas")
		fClashPenalty = MCM.GetModSettingFloat("Chemistry", "fClashPenalty:Personas")
		fAudienceBonus = MCM.GetModSettingFloat("Chemistry", "fAudienceBonus:Personas")
		fShyPenalty = MCM.GetModSettingFloat("Chemistry", "fShyPenalty:Personas")
		fFaithWeight = MCM.GetModSettingFloat("Chemistry", "fFaithWeight:Personas")
		fNearMissMargin = MCM.GetModSettingFloat("Chemistry", "fNearMissMargin:General")
		fRefusalBackoffHours = MCM.GetModSettingFloat("Chemistry", "fRefusalBackoffHours:Refusals")
		fRefusalBackoffCap = MCM.GetModSettingFloat("Chemistry", "fRefusalBackoffCap:Refusals")
		iLogLevel = MCM.GetModSettingInt("Chemistry", "iLogLevel:General")
	EndIf
	; Derived, never a setting: the early exit in Consider must be at least the most
	; the persona rules can add (kindred + two vulgar in a crowd), or it skips a pair
	; they would have lifted over the best.
	fPersonaMax = Self.AtLeast(fKindredBonus, 0.0) + 2.0 * Self.AtLeast(fAudienceBonus, 0.0)
	; One number for "how many onlookers are still privacy" (C-6), and it is Rapport's.
	iCrowdTolerance = Rapport:Core.ObserverTolerance()
EndFunction

Float Function AtLeast(Float afValue, Float afFloor)
	If afValue < afFloor
		Return afFloor
	EndIf
	Return afValue
EndFunction

Function Connect()
	; Said every time rather than once: Rapport's plugin starts fresh on every launch
	; while this script lives in the save, so "already told it" is a belief that would
	; be wrong exactly once per session. Rapport ignores a repeat.
	Rapport:Core.TakeOverDecisions("Chemistry")

	; Counters are per LOAD, not per save. A tally spanning three sessions cannot be
	; compared with anything.
	_passes = 0
	_acted = 0
	_blockedResting = 0
	_blockedBar = 0
	_blockedEmpty = 0
	_blockedBusy = 0
	_polls = 0

	; Cancel before starting, unconditionally. Both OnQuestInit and OnInit can fire,
	; and Papyrus cannot be asked whether a timer is already running -- Rapport's
	; bridge started three overlapping polls that way. A remembered flag is the thing
	; that has wedged that mod twice, so no flag: just cancel.
	Self.LoadSettings()
	Self.CancelTimer(kPollTimer)
	Self.StartTimer(fPollSeconds, kPollTimer)

	Rapport:Core.Trace("chemistry: awake. every " + Self.F2(fPollSeconds) + "s, bar " + Self.F2(fMinimumScore) + ", rest " + Self.F2(fCooldownHours) + "h, bond x" + Self.F2(fBondWeight) + " capped at +/-" + Self.F2(fBondCap) + ", log level " + iLogLevel)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != kPollTimer
		Return
	EndIf

	; The NEXT poll first, before any work. If anything below throws or stalls the
	; clock survives -- and a Chemistry that stops looking is a mod that silently does
	; nothing for the rest of the save.
	Self.StartTimer(fPollSeconds, kPollTimer)

	; Every poll, not only in Connect. OnInit runs once per SAVE, but Rapport's plugin
	; forgets the takeover on every LAUNCH - so after a restart and a load, Rapport's
	; stand-in went on choosing scenes beside Chemistry, with its own cooldown and
	; none of Chemistry's bonuses. Seen 2026-09-21: the Codmans' scene went out as
	; "Rapport,autonomy" while Chemistry was polling. One native call; Rapport ignores
	; a repeat without logging it.
	Rapport:Core.TakeOverDecisions("Chemistry")

	Self.LoadSettings()
	If !bEnabled
		Return
	EndIf
	Self.Consider()
EndEvent

; ---- the decision -------------------------------------------------------------

Function Consider()
	_passes += 1
	_polls += 1

	Bool tally = _polls >= iTallyEvery
	If tally
		_polls = 0
	EndIf

	; Nothing to decide while one is already playing, and deciding anyway is not
	; free: it reads every candidate, scores them, works out whose place it is and
	; prints a table -- all to be told no. Observed four polls in a row doing exactly
	; that during one scene.
	If Rapport:Core.Busy()
		_blockedBusy += 1
		If tally
			Rapport:Core.Trace("chemistry: pass " + _passes + " - a scene is already running, so nothing was considered." + Self.Tally())
		EndIf
		Return
	EndIf

	Self.Snapshot()
	Int count = _held
	If count <= 0
		_blockedEmpty += 1
		If tally
			Rapport:Core.Trace("chemistry: pass " + _passes + " - Rapport published nothing; no viable pair among the loaded actors." + Self.Tally())
		EndIf
		Return
	EndIf

	; Two passes over the list. The first decides, the second explains -- and the
	; second only runs when somebody is going to read it. Deciding and reporting are
	; kept apart on purpose: a logger that changes what is chosen is worse than no
	; logger, and interleaving them is how that happens.
	; The winning pair's IDS, captured when it wins. Not its index.
	;
	; Rapport republishes on its own tick, every twenty seconds, and the table below
	; takes about three seconds to print. Re-reading CandidateFirst(best) after the
	; loop therefore indexes into a list that may have been replaced since the choice
	; was made -- and then Chemistry asks for a pair it never evaluated.
	;
	; Seen in the log rather than reasoned about: pass 4 chose "Johnny Friendly +
	; Polly at 1.26" while the table printed that same pair at 1.02 and BACKED OFF.
	; Two different snapshots, one decision.
	Int best = -1
	Int bestFirst = 0
	Int bestSecond = 0
	Float bestScore = 0.0
	Int resting = 0
	Int backedOff = 0
	Int tooLow = 0
	Float highest = -99.0
	Int missFirst = 0
	Int missSecond = 0
	Int missIndex = -1

	Int i = 0
	While i < count
		Int firstID = _first[i]
		Int secondID = _second[i]

		; A published id can have unloaded since the pass that measured it. Rapport
		; hands out ids rather than Actors for exactly this reason.
		; Rapport publishes SORTED by score, and the most any bonus can add is the
		; repeat cap plus the place cap. So once a pair cannot beat the best already
		; found even with everything, nothing further down can either -- and every
		; pair skipped here is five ledger lookups not made.
		;
		; Safe for the report: the resting / backed-off / under-bar counters are only
		; read in the "nobody qualified" branch, which is reached only when there is
		; no best, in which case this never triggers.
		If best >= 0 && (_score[i] + fBondCap + fOwnPlaceBonus + fPersonaMax) <= bestScore
			i = count
		ElseIf firstID != 0 && secondID != 0
			If !Self.Available(firstID) || !Self.Available(secondID)
				backedOff += 1
			ElseIf Self.Rested(firstID) && Self.Rested(secondID)
				Float score = _score[i] + Self.BondBonus(firstID, secondID) + Self.PlaceBonus(i) + Self.PersonaBonus(i, firstID, secondID) + Self.FaithCost(firstID, secondID)
				If score > highest
					highest = score
					missFirst = firstID
					missSecond = secondID
					missIndex = i
				EndIf
				If score >= fMinimumScore
					If score > bestScore
						bestScore = score
						best = i
						bestFirst = firstID
						bestSecond = secondID
					EndIf
				Else
					tooLow += 1
				EndIf
			Else
				resting += 1
			EndIf
		EndIf
		i += 1
	EndWhile

	If best < 0
		If resting > 0 && tooLow == 0
			_blockedResting += 1
		Else
			_blockedBar += 1
		EndIf

		If iLogLevel >= 2
			Self.Table(count, 0, 0)
			Rapport:Core.Trace("chemistry:     -> nobody: " + resting + " resting, " + backedOff + " backed off, " + tooLow + " under the bar" + Self.BestNote(highest))
		ElseIf tally
			Rapport:Core.Trace("chemistry: pass " + _passes + " - passed on all " + count + " pair(s): " + resting + " resting, " + backedOff + " backed off after refusals, " + tooLow + " under the " + Self.F2(fMinimumScore) + " bar" + Self.BestNote(highest) + "." + Self.Tally())
		EndIf
		; The Narrator's "why nothing happened": only for a pair that came close, and
		; Rapport decides whether it is time to say so (it rate-limits).
		If missIndex >= 0 && highest >= fMinimumScore - fNearMissMargin
			Rapport:Core.NarrateNearMiss(missFirst, missSecond, Self.MissWhy(missIndex, missFirst, missSecond), highest, fMinimumScore)
		EndIf
		Return
	EndIf

	; From the captured ids, NOT from the list, which may have been republished.
	Actor akFirst = Game.GetForm(bestFirst) as Actor
	Actor akSecond = Game.GetForm(bestSecond) as Actor
	If akFirst == None || akSecond == None
		; A failed cast assigns None in Papyrus rather than erroring, so this is
		; checked rather than assumed.
		Rapport:Core.Trace("chemistry: pass " + _passes + " - chose pair " + best + " but one of them no longer resolves; they may have unloaded since Rapport measured them. Skipping.")
		Return
	EndIf

	; ACT FIRST, EXPLAIN AFTER.
	;
	; The table costs about three seconds of Papyrus -- measured at 190 ms a row, and
	; the VM yields between statements so it is wall time, not CPU. Logging before
	; asking meant every scene was requested three seconds after it was decided, with
	; the two of them still walking around in between. The decision is already made
	; by this point; printing it is not part of making it.
	String scenario = Self.ScenarioFor(best)
	Int quality = Rapport:Core.CanRun(scenario, akFirst, akSecond)
	Bool took = False
	If quality >= 0
		Self.ReportToNarrator(best, bestFirst, bestSecond, akFirst, akSecond)
		took = Rapport:Core.RequestScene(akFirst, akSecond, scenario)
		If took && Self.FaithCost(bestFirst, bestSecond) < 0.0
			Rapport:Core.NoteAffair(bestFirst, bestSecond)
		EndIf
		If took
			_acted += 1
		EndIf
	EndIf

	; Now say what happened, at leisure.
	If iLogLevel >= 1
		Self.Table(count, bestFirst, bestSecond)
	EndIf
	Rapport:Core.Trace("chemistry:     -> " + Self.Who(akFirst, akSecond) + " at " + Self.F2(bestScore) + ", over " + (count - 1) + " other(s)")
	Rapport:Core.Trace("chemistry:        where: " + Self.Where(best))
	Rapport:Core.Trace("chemistry:        story: " + scenario + " - " + Self.WhyScenario(best))
	Rapport:Core.Trace("chemistry:        CanRun = " + quality + ", " + Self.QualityName(quality))

	If quality < 0
		Rapport:Core.Trace("chemistry:        NOT ASKED: no scenario by that name. Check scenarios.json.")
		Return
	EndIf

	If took
		Rapport:Core.Trace("chemistry:        asked, and Rapport took it." + Self.Tally())
	Else
		; Transient by definition: a scene is already running, or the bridge is not up.
		; Said anyway, because otherwise a full table ends with nothing and reads like
		; a failure.
		Rapport:Core.Trace("chemistry:        Rapport declined for now - a scene is already running, or the bridge is not ready. Trying again next poll.")
	EndIf
EndFunction

; Take one consistent copy of what Rapport is offering.
;
; Everything after this reads the copy, so the decision and the explanation are
; about the same list. The signals (where, observers, night) are still read live by
; index -- they are only used for the ONE pair being acted on, and a stale reading
; of the room is a cosmetic error rather than a wrong choice.
Function Snapshot()
	; A literal 24, because Fallout 4 ships no Utility.psc and there is no
	; CreateIntArray to size one from a variable. iMaxPairs must match it, and is
	; what everything else reads -- they are two halves of one number.
	; !_observers too: a save from before those arrays existed has a 24-slot _first
	; and no _observers at all.
	If _first.Length != iMaxPairs || !_observers
		_first = new Int[24]
		_second = new Int[24]
		_score = new Float[24]
		_whose = new Int[24]
		_observers = new Int[24]
		_interior = new Bool[24]
		_night = new Bool[24]
		_faction = new Bool[24]
		_playerNear = new Bool[24]
		_distance = new Float[24]
	EndIf

	Int count = Rapport:Core.CandidateCount()
	If count > iMaxPairs
		count = iMaxPairs
	EndIf

	Int i = 0
	While i < count
		_first[i] = Rapport:Core.CandidateFirst(i)
		_second[i] = Rapport:Core.CandidateSecond(i)
		_score[i] = Rapport:Core.CandidateScore(i)
		_observers[i] = Rapport:Core.CandidateObservers(i)
		_interior[i] = Rapport:Core.CandidateInterior(i)
		_night[i] = Rapport:Core.CandidateNight(i)
		_faction[i] = Rapport:Core.CandidateSharedFaction(i)
		_playerNear[i] = Rapport:Core.CandidatePlayerNear(i)
		_distance[i] = Rapport:Core.CandidateDistance(i)
		_whose[i] = Self.WhosePlace(i, _first[i], _second[i])
		i += 1
	EndWhile
	_held = count
EndFunction

; ---- the table ----------------------------------------------------------------
;
; One line per published pair: what Rapport scored it, what history added, and the
; verdict with the NUMBER behind it. "Resting" without saying how long, or "under the
; bar" without saying by how much, is the kind of line that looks like an explanation
; and is not one.
Function Table(Int aiCount, Int aiChosenFirst, Int aiChosenSecond)
	Rapport:Core.Trace("chemistry: pass " + _passes + " | " + aiCount + " pair(s) published | score + bonus = total | verdict  (bonus = bond, whose place it is, and personas)")

	Int i = 0
	While i < aiCount
		Int firstID = _first[i]
		Int secondID = _second[i]
		If firstID != 0 && secondID != 0
			Float raw = _score[i]
			Float hist = Self.BondBonus(firstID, secondID) + Self.PlaceBonus(i) + Self.PersonaBonus(i, firstID, secondID) + Self.FaithCost(firstID, secondID)

			; Marked by WHO, not by index. The list can be republished between the
			; decision and this table, and an index would then point at whoever
			; happens to be in that slot now.
			String mark = "     "
			If firstID == aiChosenFirst && secondID == aiChosenSecond
				mark = "  -> "
			EndIf

			Rapport:Core.Trace("chemistry:" + mark + "[" + i + "] " + Self.WhoByID(firstID, secondID) + " | " + Self.F2(raw) + " + " + Self.F2(hist) + " = " + Self.F2(raw + hist) + " | " + Self.Verdict(firstID, secondID, raw + hist, _whose[i]))
		EndIf
		i += 1
	EndWhile
EndFunction

; Why this pair is or is not available, with the number that decided it.
String Function Verdict(Int aiFirst, Int aiSecond, Float afTotal, Int aiWhose)
	If !Self.Available(aiFirst)
		Return "BACKED OFF - " + Self.NameOf(aiFirst) + " refused " + Rapport:Core.RefusalCount(aiFirst) + "x, last " + Self.F2(Rapport:Core.HoursSinceRefusal(aiFirst)) + "h ago, waiting " + Self.F2(Self.BackoffFor(aiFirst)) + "h"
	EndIf
	If !Self.Available(aiSecond)
		Return "BACKED OFF - " + Self.NameOf(aiSecond) + " refused " + Rapport:Core.RefusalCount(aiSecond) + "x, last " + Self.F2(Rapport:Core.HoursSinceRefusal(aiSecond)) + "h ago, waiting " + Self.F2(Self.BackoffFor(aiSecond)) + "h"
	EndIf

	Float restFirst = Rapport:Core.HoursSinceScene(aiFirst)
	Float restSecond = Rapport:Core.HoursSinceScene(aiSecond)

	If restFirst < fCooldownHours
		Return "RESTING - " + Self.NameOf(aiFirst) + " " + Self.F2(restFirst) + "h of " + Self.F2(fCooldownHours) + "h"
	EndIf
	If restSecond < fCooldownHours
		Return "RESTING - " + Self.NameOf(aiSecond) + " " + Self.F2(restSecond) + "h of " + Self.F2(fCooldownHours) + "h"
	EndIf
	If afTotal < fMinimumScore
		Return "under the bar by " + Self.F2(fMinimumScore - afTotal)
	EndIf

	Int met = Rapport:Core.PairSceneCount(aiFirst, aiSecond)
	String note = "eligible"
	If met > 0
		note = note + ", together " + met + " time(s) before"
	EndIf
	note = note + ", personas " + Rapport:Core.PersonaOf(aiFirst) + "/" + Rapport:Core.PersonaOf(aiSecond)
	note = note + ", bond " + Self.F2(Rapport:Relations.BondBetween(Game.GetForm(aiFirst) as Actor, Game.GetForm(aiSecond) as Actor))
	If aiWhose == 2
		note = note + ", and one of them lives here"
	ElseIf aiWhose == 1
		note = note + ", in their faction's place"
	EndIf
	Return note
EndFunction

; ---- the measurements, in words -----------------------------------------------

String Function Where(Int aiIndex)
	String out = "outdoors"
	If _interior[aiIndex]
		out = "indoors"
	EndIf

	Int watching = _observers[aiIndex]
	If watching == 0
		out = out + ", nobody watching"
	ElseIf watching == 1
		out = out + ", 1 watching"
	Else
		out = out + ", " + watching + " watching"
	EndIf

	If _night[aiIndex]
		out = out + ", night"
	Else
		out = out + ", daytime"
	EndIf

	out = out + ", " + Self.F2(_distance[aiIndex]) + " units apart"

	If _faction[aiIndex]
		out = out + ", same faction"
	EndIf

	; Reported, never acted on. The player is not a factor by decision (DESIGN C-4),
	; and the difference between "ignored" and "never measured" is worth being able to
	; see in the log.
	If _playerNear[aiIndex]
		out = out + ", player nearby (ignored by policy)"
	EndIf
	Return out
EndFunction

String Function WhyScenario(Int aiIndex)
	Int whose = _whose[aiIndex]
	If whose == 2
		Return "one of them lives here, so the room is theirs however many are about"
	EndIf
	If whose == 1
		Return "their faction's building - not private, but not a street either"
	EndIf
	If _interior[aiIndex] && _observers[aiIndex] <= iCrowdTolerance
		Return "indoors and nobody who counts as a crowd, so there is time to take"
	EndIf
	If _observers[aiIndex] <= iCrowdTolerance
		If Self.EitherIs(aiIndex, "vulgar")
			Return "out in the open, and one of them is vulgar: no taking it slow"
		EndIf
		Return "out in the open but not crowded: unhurried, not private"
	EndIf
	Return "more than " + iCrowdTolerance + " watching, so too busy for anything long"
EndFunction

String Function QualityName(Int aiQuality)
	If aiQuality < 0
		Return "NO SUCH SCENARIO"
	ElseIf aiQuality == 0
		Return "nothing in the catalogue fits this pair. It will still play, but AAF chooses and there is no guaranteed ending"
	ElseIf aiQuality == 1
		Return "the scenario constrains nothing by design; AAF chooses"
	ElseIf aiQuality == 2
		Return "a tree was found, but nothing guarantees it reaches a climax"
	EndIf
	Return "a matching tree that is known to finish"
EndFunction

String Function Tally()
	Return " [this load: " + _passes + " passes, " + _acted + " acted, " + _blockedBusy + " while-busy, " + _blockedResting + " all-resting, " + _blockedBar + " under-bar, " + _blockedEmpty + " nothing-published]"
EndFunction

String Function BestNote(Float afHighest)
	If afHighest < -90.0
		Return " (nothing was even eligible to score)"
	EndIf
	Return " (best eligible was " + Self.F2(afHighest) + ")"
EndFunction

; ---- names --------------------------------------------------------------------
;
; Names, not form ids. A table of 0002F0B and 000F61B6 is unreadable, and being
; unreadable is the only way this logger can fail at its job.
;
; The name has to come from Rapport, because Fallout 4's base Papyrus has no way to
; ask for one: no GetName on Form, no GetDisplayName on ObjectReference, nothing on
; Actor. Rapport:Core.ActorName exists for exactly this.
String Function NameOf(Int aiFormID)
	Actor who = Game.GetForm(aiFormID) as Actor
	If who == None
		Return "[gone]"
	EndIf
	String named = Rapport:Core.ActorName(who)
	If named == ""
		Return "[unnamed]"
	EndIf
	Return named
EndFunction

String Function Who(Actor akFirst, Actor akSecond)
	Return Rapport:Core.ActorName(akFirst) + " + " + Rapport:Core.ActorName(akSecond)
EndFunction

String Function WhoByID(Int aiFirst, Int aiSecond)
	Return Self.NameOf(aiFirst) + " + " + Self.NameOf(aiSecond)
EndFunction

; ---- two decimal places -------------------------------------------------------
;
; Papyrus prints a Float with everything it has: 1.8400001 rather than 1.84. In a
; table that is the difference between scannable and not, and being scannable is the
; whole point of the table.
String Function F2(Float afValue)
	; Guarded, because one of the values that reaches this is 1e9: HoursSinceScene
	; returns it for an actor who has never had a scene. (1e9 * 100) as Int overflows
	; a 32-bit Int and prints garbage. Every current caller happens to filter that
	; out first, which is exactly the kind of accident that stops being true later.
	If afValue > 1000000.0
		Return "never"
	EndIf
	If afValue < -1000000.0
		Return "?"
	EndIf

	Bool negative = afValue < 0.0
	Float size = afValue
	If negative
		size = 0.0 - size
	EndIf

	Int hundredths = ((size * 100.0) + 0.5) as Int
	Int whole = hundredths / 100
	Int frac = hundredths % 100

	String fracText = frac as String
	If frac < 10
		fracText = "0" + fracText
	EndIf

	String out = whole + "." + fracText
	If negative
		out = "-" + out
	EndIf
	Return out
EndFunction

; ---- policy -------------------------------------------------------------------

; Whose place is this?
;
;   2  one of them owns this cell
;   1  their faction owns it
;   0  nobody's, or somebody else's, or outdoors
;
; Only asked for INTERIOR pairs. An exterior cell being unowned says nothing, and
; asking would cost two native calls for every actor in every pair on every pass --
; up to forty-eight of them -- to learn nothing.
Int Function WhosePlace(Int aiIndex, Int aiFirst, Int aiSecond)
	If !_interior[aiIndex]
		Return 0
	EndIf

	Actor a = Game.GetForm(aiFirst) as Actor
	Actor b = Game.GetForm(aiSecond) as Actor
	If a == None || b == None
		Return 0
	EndIf

	Cell where = a.GetParentCell()
	If where == None
		Return 0
	EndIf

	ActorBase owner = where.GetActorOwner()
	If owner != None && (owner == a.GetActorBase() || owner == b.GetActorBase())
		Return 2
	EndIf

	Faction owningFaction = where.GetFactionOwner()
	If owningFaction != None && (a.IsInFaction(owningFaction) || b.IsInFaction(owningFaction))
		Return 1
	EndIf
	Return 0
EndFunction

; From the snapshot, never recomputed.
; What being partnered to someone ELSE costs this pair (<= 0).
Float Function FaithCost(Int aiFirst, Int aiSecond)
	Actor a = Game.GetForm(aiFirst) as Actor
	Actor b = Game.GetForm(aiSecond) as Actor
	If a == None || b == None || fFaithWeight <= 0.0 || Rapport:Relations.ArePartners(a, b)
		Return 0.0
	EndIf
	Float cost = 0.0
	If Rapport:Relations.HasPartner(a)
		cost -= fFaithWeight * Rapport:Core.FaithfulnessOf(aiFirst)
	EndIf
	If Rapport:Relations.HasPartner(b)
		cost -= fFaithWeight * Rapport:Core.FaithfulnessOf(aiSecond)
	EndIf
	Return cost
EndFunction

; Chemistry's own share of the score, told to Rapport's Narrator just before the
; request, so its numbers line adds up to what decided. Zero parts are skipped there.
Function ReportToNarrator(Int aiIndex, Int aiFirst, Int aiSecond, Actor akFirst, Actor akSecond)
	Rapport:Core.NarrateBonus(aiFirst, aiSecond, "bond", Self.BondBonus(aiFirst, aiSecond))
	If _whose[aiIndex] == 2
		Rapport:Core.NarrateBonus(aiFirst, aiSecond, "own place", fOwnPlaceBonus)
	ElseIf _whose[aiIndex] == 1
		Rapport:Core.NarrateBonus(aiFirst, aiSecond, "their faction's place", fFactionPlaceBonus)
	EndIf
	Rapport:Core.NarrateBonus(aiFirst, aiSecond, "personas", Self.PersonaBonus(aiIndex, aiFirst, aiSecond))
	Rapport:Core.NarrateBonus(aiFirst, aiSecond, "spoken for", Self.FaithCost(aiFirst, aiSecond))
	If Rapport:Relations.ArePartners(akFirst, akSecond)
		; A zero-valued marker: the store only learns they are a couple when the scene
		; starts, after the Narrator has spoken.
		Rapport:Core.NarrateBonus(aiFirst, aiSecond, "couple", 0.0)
	EndIf
EndFunction

; Why the closest pair did not happen, as a clause with no names in it.
String Function MissWhy(Int aiIndex, Int aiFirst, Int aiSecond)
	If _observers[aiIndex] > iCrowdTolerance
		Return _observers[aiIndex] + " people are watching"
	EndIf
	If Self.FaithCost(aiFirst, aiSecond) < -0.2
		Return "one of them is spoken for"
	EndIf
	If !_night[aiIndex] && !_interior[aiIndex]
		Return "it's broad daylight out in the open"
	EndIf
	Return "the moment isn't quite right"
EndFunction

Float Function PlaceBonus(Int aiIndex)
	Int whose = _whose[aiIndex]
	If whose == 2
		Return fOwnPlaceBonus
	ElseIf whose == 1
		Return fFactionPlaceBonus
	EndIf
	Return 0.0
EndFunction

; How long this actor must wait after their refusals, escalating with how many.
Float Function BackoffFor(Int aiFormID)
	Int refusals = Rapport:Core.RefusalCount(aiFormID)
	If refusals <= 0
		Return 0.0
	EndIf
	Float wait = fRefusalBackoffHours * refusals
	If wait > fRefusalBackoffCap
		Return fRefusalBackoffCap
	EndIf
	Return wait
EndFunction

; False while an actor AAF keeps refusing is still in their backoff.
Bool Function Available(Int aiFormID)
	Float wait = Self.BackoffFor(aiFormID)
	If wait <= 0.0
		Return True
	EndIf
	Return Rapport:Core.HoursSinceRefusal(aiFormID) >= wait
EndFunction

Bool Function Rested(Int aiFormID)
	Return Rapport:Core.HoursSinceScene(aiFormID) >= fCooldownHours
EndFunction

Float Function BondBonus(Int aiFirst, Int aiSecond)
	Float bonus = fBondWeight * Rapport:Relations.BondBetween(Game.GetForm(aiFirst) as Actor, Game.GetForm(aiSecond) as Actor)
	If bonus > fBondCap
		Return fBondCap
	ElseIf bonus < -fBondCap
		Return -fBondCap
	EndIf
	Return bonus
EndFunction

; DESIGN C-8. What their personas make of each other, and of an audience.
Float Function PersonaBonus(Int aiIndex, Int aiFirst, Int aiSecond)
	String a = Rapport:Core.PersonaOf(aiFirst)
	String b = Rapport:Core.PersonaOf(aiSecond)
	Float bonus = 0.0
	If a != "" && a == b
		bonus += fKindredBonus
	ElseIf (a == "romantic" && b == "vulgar") || (a == "vulgar" && b == "romantic")
		bonus -= fClashPenalty
	EndIf
	If _observers[aiIndex] > iCrowdTolerance
		If a == "vulgar"
			bonus += fAudienceBonus
		ElseIf a == "reticent"
			bonus -= fShyPenalty
		EndIf
		If b == "vulgar"
			bonus += fAudienceBonus
		ElseIf b == "reticent"
			bonus -= fShyPenalty
		EndIf
	EndIf
	Return bonus
EndFunction

Bool Function EitherIs(Int aiIndex, String asPersona)
	Return Rapport:Core.PersonaOf(_first[aiIndex]) == asPersona || Rapport:Core.PersonaOf(_second[aiIndex]) == asPersona
EndFunction

; DESIGN C-6. Privacy buys time, and the line between private and public is the same
; number Rapport already uses.
;
; The first version of this used 0 and 1, and the log made it obviously wrong within
; two scenes: it called "quickie" on a pair with two onlookers, while Rapport scored
; those same two onlookers at exactly zero cost. One layer said two watchers are
; nothing and the other said too busy for anything long. Owner settled it on the side
; of Rapport's own tolerance -- in this world nobody is shy, and two people nearby is
; not a crowd.
;
; So: indoors and uncrowded gets the long story, out in the open but uncrowded gets
; the slow one, and an actual crowd gets something brief.
;
; The player is deliberately not consulted (DESIGN C-4).
String Function ScenarioFor(Int aiIndex)
	; Their own place earns the long story whatever the room count. Somebody walking
	; through your house is not the same as an audience in a market, and the whole
	; point of knowing whose place it is, is to stop treating them alike.
	Int whose = _whose[aiIndex]
	If whose == 2
		Return "athome"
	EndIf
	If _interior[aiIndex] && _observers[aiIndex] <= iCrowdTolerance
		Return "athome"
	EndIf
	If _observers[aiIndex] <= iCrowdTolerance
		; C-8: in the open, a vulgar one does not take it slow.
		If Self.EitherIs(aiIndex, "vulgar")
			Return "quickie"
		EndIf
		Return "tender"
	EndIf
	Return "quickie"
EndFunction
