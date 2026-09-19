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
; Numbers, not decisions. The decisions they implement are in DESIGN.md as C-1 to
; C-5; these are the first guesses at what they should be worth. They live here
; rather than in an ini because Chemistry has no native code to read one.

Float Property fPollSeconds = 30.0 AutoReadOnly
Float Property fCooldownHours = 24.0 AutoReadOnly
Float Property fMinimumScore = 0.90 AutoReadOnly
Float Property fRepeatBonus = 0.15 AutoReadOnly
Float Property fRepeatCap = 0.45 AutoReadOnly

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
Int Property iLogLevel = 1 AutoReadOnly
Int Property iTallyEvery = 10 AutoReadOnly

; ---- state, in the save -------------------------------------------------------
Int _polls = 0            ; since the last tally
Int _passes = 0           ; since this load
Int _acted = 0
Int _blockedResting = 0   ; passes where everything eligible was resting
Int _blockedBar = 0       ; passes where the best was under the bar
Int _blockedEmpty = 0     ; passes where Rapport published nothing

; ---- lifecycle ----------------------------------------------------------------

Event OnQuestInit()
	Self.Connect()
EndEvent

Event OnInit()
	Self.Connect()
EndEvent

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
	_polls = 0

	; Cancel before starting, unconditionally. Both OnQuestInit and OnInit can fire,
	; and Papyrus cannot be asked whether a timer is already running -- Rapport's
	; bridge started three overlapping polls that way. A remembered flag is the thing
	; that has wedged that mod twice, so no flag: just cancel.
	Self.CancelTimer(kPollTimer)
	Self.StartTimer(fPollSeconds, kPollTimer)

	Rapport:Core.Trace("chemistry: awake. every " + Self.F2(fPollSeconds) + "s, bar " + Self.F2(fMinimumScore) + ", rest " + Self.F2(fCooldownHours) + "h, history +" + Self.F2(fRepeatBonus) + " each to a cap of +" + Self.F2(fRepeatCap) + ", log level " + iLogLevel)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != kPollTimer
		Return
	EndIf

	; The NEXT poll first, before any work. If anything below throws or stalls the
	; clock survives -- and a Chemistry that stops looking is a mod that silently does
	; nothing for the rest of the save.
	Self.StartTimer(fPollSeconds, kPollTimer)

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

	Int count = Rapport:Core.CandidateCount()
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
	Int best = -1
	Float bestScore = 0.0
	Int resting = 0
	Int tooLow = 0
	Float highest = -99.0

	Int i = 0
	While i < count
		Int firstID = Rapport:Core.CandidateFirst(i)
		Int secondID = Rapport:Core.CandidateSecond(i)

		; A published id can have unloaded since the pass that measured it. Rapport
		; hands out ids rather than Actors for exactly this reason.
		If firstID != 0 && secondID != 0
			If Self.Rested(firstID) && Self.Rested(secondID)
				Float score = Rapport:Core.CandidateScore(i) + Self.RepeatBonus(firstID, secondID)
				If score > highest
					highest = score
				EndIf
				If score >= fMinimumScore
					If score > bestScore
						bestScore = score
						best = i
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
			Self.Table(count, -1)
			Rapport:Core.Trace("chemistry:     -> nobody: " + resting + " resting, " + tooLow + " under the bar" + Self.BestNote(highest))
		ElseIf tally
			Rapport:Core.Trace("chemistry: pass " + _passes + " - passed on all " + count + " pair(s): " + resting + " resting, " + tooLow + " under the " + Self.F2(fMinimumScore) + " bar" + Self.BestNote(highest) + "." + Self.Tally())
		EndIf
		Return
	EndIf

	Actor akFirst = Game.GetForm(Rapport:Core.CandidateFirst(best)) as Actor
	Actor akSecond = Game.GetForm(Rapport:Core.CandidateSecond(best)) as Actor
	If akFirst == None || akSecond == None
		; A failed cast assigns None in Papyrus rather than erroring, so this is
		; checked rather than assumed.
		Rapport:Core.Trace("chemistry: pass " + _passes + " - chose pair " + best + " but one of them no longer resolves; they may have unloaded since Rapport measured them. Skipping.")
		Return
	EndIf

	; From here it is going to act, so say everything.
	If iLogLevel >= 1
		Self.Table(count, best)
	EndIf

	String scenario = Self.ScenarioFor(best)
	Rapport:Core.Trace("chemistry:     -> " + Self.Who(akFirst, akSecond) + " at " + Self.F2(bestScore) + ", over " + (count - 1) + " other(s)")
	Rapport:Core.Trace("chemistry:        where: " + Self.Where(best))
	Rapport:Core.Trace("chemistry:        story: " + scenario + " - " + Self.WhyScenario(best))

	Int quality = Rapport:Core.CanRun(scenario, akFirst, akSecond)
	Rapport:Core.Trace("chemistry:        CanRun = " + quality + ", " + Self.QualityName(quality))
	If quality < 0
		Rapport:Core.Trace("chemistry:        NOT ASKING: no scenario by that name. Check scenarios.json.")
		Return
	EndIf

	If Rapport:Core.RequestScene(akFirst, akSecond, scenario)
		_acted += 1
		Rapport:Core.Trace("chemistry:        asked, and Rapport took it." + Self.Tally())
	Else
		; Transient by definition: a scene is already running, or the bridge is not up.
		; Said anyway, because otherwise a full table ends with nothing and reads like
		; a failure.
		Rapport:Core.Trace("chemistry:        Rapport declined for now - a scene is already running, or the bridge is not ready. Trying again next poll.")
	EndIf
EndFunction

; ---- the table ----------------------------------------------------------------
;
; One line per published pair: what Rapport scored it, what history added, and the
; verdict with the NUMBER behind it. "Resting" without saying how long, or "under the
; bar" without saying by how much, is the kind of line that looks like an explanation
; and is not one.
Function Table(Int aiCount, Int aiChosen)
	Rapport:Core.Trace("chemistry: pass " + _passes + " | " + aiCount + " pair(s) published | score + history = total | verdict")

	Int i = 0
	While i < aiCount
		Int firstID = Rapport:Core.CandidateFirst(i)
		Int secondID = Rapport:Core.CandidateSecond(i)
		If firstID != 0 && secondID != 0
			Float raw = Rapport:Core.CandidateScore(i)
			Float hist = Self.RepeatBonus(firstID, secondID)

			String mark = "     "
			If i == aiChosen
				mark = "  -> "
			EndIf

			Rapport:Core.Trace("chemistry:" + mark + "[" + i + "] " + Self.WhoByID(firstID, secondID) + " | " + Self.F2(raw) + " + " + Self.F2(hist) + " = " + Self.F2(raw + hist) + " | " + Self.Verdict(firstID, secondID, raw + hist))
		EndIf
		i += 1
	EndWhile
EndFunction

; Why this pair is or is not available, with the number that decided it.
String Function Verdict(Int aiFirst, Int aiSecond, Float afTotal)
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
	If met > 0
		Return "eligible, together " + met + " time(s) before"
	EndIf
	Return "eligible"
EndFunction

; ---- the measurements, in words -----------------------------------------------

String Function Where(Int aiIndex)
	String out = "outdoors"
	If Rapport:Core.CandidateInterior(aiIndex)
		out = "indoors"
	EndIf

	Int watching = Rapport:Core.CandidateObservers(aiIndex)
	If watching == 0
		out = out + ", nobody watching"
	ElseIf watching == 1
		out = out + ", 1 watching"
	Else
		out = out + ", " + watching + " watching"
	EndIf

	If Rapport:Core.CandidateNight(aiIndex)
		out = out + ", night"
	Else
		out = out + ", daytime"
	EndIf

	out = out + ", " + Self.F2(Rapport:Core.CandidateDistance(aiIndex)) + " units apart"

	If Rapport:Core.CandidateSharedFaction(aiIndex)
		out = out + ", same faction"
	EndIf

	; Reported, never acted on. The player is not a factor by decision (DESIGN C-4),
	; and the difference between "ignored" and "never measured" is worth being able to
	; see in the log.
	If Rapport:Core.CandidatePlayerNear(aiIndex)
		out = out + ", player nearby (ignored by policy)"
	EndIf
	Return out
EndFunction

String Function WhyScenario(Int aiIndex)
	If Rapport:Core.CandidateInterior(aiIndex) && Rapport:Core.CandidateObservers(aiIndex) == 0
		Return "indoors with nobody watching, so there is time to take. ASSUMPTION, see DESIGN.md"
	EndIf
	If Rapport:Core.CandidateObservers(aiIndex) <= 1
		Return "one onlooker or fewer: unhurried but not private. ASSUMPTION, see DESIGN.md"
	EndIf
	Return "too busy for anything long. ASSUMPTION, see DESIGN.md"
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
	Return " [this load: " + _passes + " passes, " + _acted + " acted, " + _blockedResting + " all-resting, " + _blockedBar + " under-bar, " + _blockedEmpty + " nothing-published]"
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

Bool Function Rested(Int aiFormID)
	Return Rapport:Core.HoursSinceScene(aiFormID) >= fCooldownHours
EndFunction

Float Function RepeatBonus(Int aiFirst, Int aiSecond)
	Int met = Rapport:Core.PairSceneCount(aiFirst, aiSecond)
	If met <= 0
		Return 0.0
	EndIf
	Float bonus = fRepeatBonus * met
	If bonus > fRepeatCap
		Return fRepeatCap
	EndIf
	Return bonus
EndFunction

; ASSUMPTION, not a settled decision -- flagged in DESIGN.md as the first thing to
; confirm. The reasoning: privacy buys time. Somewhere private and empty is where two
; people would take their time; a corner of a market is where they would not.
;
; The player is deliberately not consulted (DESIGN C-4).
String Function ScenarioFor(Int aiIndex)
	If Rapport:Core.CandidateInterior(aiIndex) && Rapport:Core.CandidateObservers(aiIndex) == 0
		Return "athome"
	EndIf
	If Rapport:Core.CandidateObservers(aiIndex) <= 1
		Return "tender"
	EndIf
	Return "quickie"
EndFunction
