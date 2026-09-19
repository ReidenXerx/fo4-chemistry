Scriptname Chemistry:Autonomy extends Quest
{Chemistry: the whole of it.

 Rapport does the work; this decides. Every pass Rapport enumerates the loaded
 actors, drops the children, the wrong races, the quest actors with running
 packages and the hostiles, ranks every remaining pair and publishes what it
 measured. None of that is here and none of it should be -- Player Proposals will
 want all of it too.

 What is here is policy: whether any of those pairs is worth acting on now.

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
; Numbers, not decisions. The decisions they implement are in docs/DESIGN.md; these
; are the first guesses at what they should be worth, and they are here rather than
; in an ini because Chemistry has no native code to read one.

; How often to look. Rapport scores every 20s, so anything faster only re-reads the
; same publication.
Float Property fPollSeconds = 30.0 AutoReadOnly

; Per-ACTOR rest after a scene, in GAME hours. Per actor rather than per pair
; deliberately: it stops one settler working through three partners in an evening,
; which is the thing that would read as a mod rather than as people.
Float Property fCooldownHours = 24.0 AutoReadOnly

; What a pair has to be worth before Chemistry acts. Rapport reports its own bar
; (MinimumScore in Rapport.ini, 0.90) and never enforces it; this is Chemistry's.
Float Property fMinimumScore = 0.90 AutoReadOnly

; The repeat bonus, per previous scene together, and the ceiling on it. Small on
; purpose: enough that couples emerge over a playthrough, capped so the same two
; cannot monopolise a settlement. docs/ideas.md calls that failure a rut.
Float Property fRepeatBonus = 0.15 AutoReadOnly
Float Property fRepeatCap = 0.45 AutoReadOnly

; How often to say what it saw, in polls. A Chemistry that decides not to act says
; nothing otherwise, and then "nothing is happening here" and "Chemistry is not
; running" look exactly alike in the log -- the worst shape a failure can have.
Int Property iReportEvery = 10 AutoReadOnly

; Polls since the last report. Lives in the save with the rest of this script.
Int _polls = 0

; ---- lifecycle ----------------------------------------------------------------

Event OnQuestInit()
	Self.Connect()
EndEvent

Event OnInit()
	Self.Connect()
EndEvent

Function Connect()
	; Said every time rather than once: Rapport's plugin starts fresh on every
	; launch while this script lives in the save, so "already told it" is a belief
	; that would be wrong exactly once per session. Rapport ignores a repeat.
	Rapport:Core.TakeOverDecisions("Chemistry")

	; Cancel before starting, unconditionally. Both OnQuestInit and OnInit can fire,
	; and Papyrus cannot be asked whether a timer is already running -- Rapport's
	; bridge started three overlapping polls that way. A remembered flag is the
	; thing that has wedged that mod twice, so no flag: just cancel.
	Self.CancelTimer(kPollTimer)
	Self.StartTimer(fPollSeconds, kPollTimer)
	Rapport:Core.Trace("chemistry: awake, looking every " + fPollSeconds + "s")
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != kPollTimer
		Return
	EndIf

	; The NEXT poll first, before any work. If anything below throws or stalls, the
	; clock survives -- and a Chemistry that stops looking is a mod that silently
	; does nothing for the rest of the save.
	Self.StartTimer(fPollSeconds, kPollTimer)

	Self.Consider()
EndEvent

; ---- the decision -------------------------------------------------------------

Function Consider()
	_polls += 1
	Bool report = _polls >= iReportEvery
	If report
		_polls = 0
	EndIf

	Int count = Rapport:Core.CandidateCount()
	If count <= 0
		If report
			Rapport:Core.Trace("chemistry: nothing published this pass - no viable pair anywhere loaded")
		EndIf
		Return
	EndIf

	Int best = -1
	Float bestScore = 0.0

	; These exist only so the report can say WHY nothing happened. A count of zero
	; acted-on with no reason attached is what wastes a morning.
	Int resting = 0
	Int tooLow = 0
	Float highest = 0.0

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
		If report
			Rapport:Core.Trace("chemistry: passed on all " + count + " pair(s) - " + resting + " still resting, " + tooLow + " under the " + fMinimumScore + " bar (best was " + highest + ")")
		EndIf
		Return
	EndIf

	Actor akFirst = Game.GetForm(Rapport:Core.CandidateFirst(best)) as Actor
	Actor akSecond = Game.GetForm(Rapport:Core.CandidateSecond(best)) as Actor
	If akFirst == None || akSecond == None
		; A failed cast assigns None in Papyrus rather than erroring, so this is
		; checked rather than assumed.
		Return
	EndIf

	String scenario = Self.ScenarioFor(best)

	; Ask before walking them anywhere. -1 is the only refusal; 0 through 3 all
	; play, and differ in how strong a promise Rapport can make about the ending.
	; Two women get 0 on a stock install because no female/female position in AAF's
	; content enters a position tree -- which is a reason to expect a vaguer scene,
	; not a reason to skip them.
	Int quality = Rapport:Core.CanRun(scenario, akFirst, akSecond)
	If quality < 0
		Rapport:Core.Trace("chemistry: no scenario called \"" + scenario + "\" - nothing to ask for")
		Return
	EndIf

	If Rapport:Core.RequestScene(akFirst, akSecond, scenario)
		Rapport:Core.Trace("chemistry: asked for \"" + scenario + "\" at score " + bestScore + " (quality " + quality + ", chosen from " + count + " pair(s), " + resting + " resting)")
	EndIf
	; A False needs nothing said: it means a scene is already running or the bridge
	; is not up, both transient, and the next poll is already scheduled.
EndFunction

; Has this actor rested long enough? HoursSinceScene returns a very large number
; for somebody who never had one, so nobody needs a special case for "never".
Bool Function Rested(Int aiFormID)
	Return Rapport:Core.HoursSinceScene(aiFormID) >= fCooldownHours
EndFunction

; A pair with history is worth a little more. PairSceneCount survives either of
; them being with somebody else, which LastPartner does not -- without it no couple
; could ever emerge because the memory would decay the moment a settlement got
; interesting.
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

; Which story fits where they are.
;
; ASSUMPTION, not a settled decision -- flagged in docs/DESIGN.md as the first
; thing to confirm. The reasoning: privacy buys time. Somewhere private and empty
; is where two people would take their time; a corner of a market is where they
; would not. So privacy chooses how unhurried the scenario is, which is the same
; "believability over frequency" line the rest of this follows.
;
; The player is deliberately not consulted. Owner's decision: the player is not a
; factor, and Rapport's own scoring weight for them is 0.
String Function ScenarioFor(Int aiIndex)
	If Rapport:Core.CandidateInterior(aiIndex) && Rapport:Core.CandidateObservers(aiIndex) == 0
		Return "athome"
	EndIf
	If Rapport:Core.CandidateObservers(aiIndex) <= 1
		Return "tender"
	EndIf
	Return "quickie"
EndFunction
