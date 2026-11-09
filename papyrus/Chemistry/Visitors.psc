Scriptname Chemistry:Visitors extends Quest
{Chemistry: Vulgar Settlers & Visitors' pairing, sent through Rapport.

 Dudu's GO, 2026-11-09. Vulgar Settlers & Visitors (Nexus 93924, z80dev) starts AAF
 scenes between Settlement Visitors' visitors and settlers on its own, with none of
 Rapport's orientation, personas, consent, private spots, faces or voices. This
 switches VSV's own pairing off and does the same job here, through
 Rapport:Core.RequestScene.

 OUR OWN CODE ONLY. VSV's permissions forbid modifying or using its assets, so this
 ships none of its files and overrides none of its records. It reads VSV's option
 globals at runtime (so VSV's own MCM page keeps choosing who and when) and writes
 exactly one: Vulgar_Enabled, which VSV's own script checks before it does anything.
 Referencing a form at runtime is not using an asset.

 What VSV does was read from its compiled script (VulgarQuestScript.pex in
 VulgarVisitors2 - Main.ba2, v2.0.1), not guessed:
   - only at a player-owned workshop the player is standing in;
   - the people are the actors whose WorkshopLinkHome points at the workshop's
     sandbox marker (or its centre marker), GetActorsLinkedToMe;
   - shuffled; a first person, then a partner within 500 units;
   - nobody dead, unconscious, in a scene, AAF-busy, a child, or not human/ghoul;
   - Allow Settlers / Settlers ONLY / sitting / Indoors / Nighttime (20:00-08:00) /
     F/F / M/M as its menu says;
   - after a scene, Cooldown minutes; after finding nobody, 90 seconds.
 Dropped on purpose: threesomes (pairs only), creatures (Rapport has no creature
 scenes), the belly morphs (Inflation/Deflation), and the scene-shape options
 (Duration, Skip Walk, Furniture Preference, Male Receiver): Rapport's scenario
 decides those. Rapport's orientation decides who is willing; VSV's M/M and F/F
 switches stay as the player's filter on top.

 Indoors/Sheltered Only: VSV counts "sheltered" with a Garden of Eden raycast when
 that is installed and ignores the option when it is not. Here it means an interior
 cell, always: one rule, no optional dependency.

 Soft dependency: without VulgarVisitors2.esm this does nothing at all.

 Style note: the base sources are decompiled and carry no default argument values,
 so every argument is passed explicitly.}

; ONE timer id, cancelled before it is started (see Autonomy.psc for why).
Int Property kTick = 1 AutoReadOnly
Float Property kTickSeconds = 30.0 AutoReadOnly
; VSV's own numbers (VulgarQuestScript.pex).
Float Property kRetrySeconds = 90.0 AutoReadOnly
Float Property kPartnerReach = 500.0 AutoReadOnly
; Rapport's API version this needs: ModSetting* and PlayerHoldsSlot (as Autonomy).
Int Property iNeedsRapport = 201 AutoReadOnly
; Asks per tick. A refusal is usually about the pair (orientation, consent), so the
; next pair is worth asking; a busy Rapport refuses them all, so not too many.
Int Property kMaxAsks = 4 AutoReadOnly

; ---- the one setting ----------------------------------------------------------
Bool bVisitors = True

; ---- VSV's forms, looked up on every load ------------------------------------
GlobalVariable _enabled
GlobalVariable _allowSettlers
GlobalVariable _ff
GlobalVariable _mm
GlobalVariable _nightOnly
GlobalVariable _indoorOnly
GlobalVariable _cooldown
GlobalVariable _settlersOnly
GlobalVariable _allowSitting
Keyword _visitor

; ---- the game's and AAF's ----------------------------------------------------
Quest _workshopParent
GlobalVariable _gameHour
Keyword _linkSandbox
Keyword _linkCenter
Keyword _linkHome
Keyword _settlement
Keyword _human
Keyword _ghoul
Keyword _child
Keyword _aafBusy
Keyword _aafLocked

; ---- state --------------------------------------------------------------------
; The player's own VSV switch from before Chemistry took the pairing over, so it can
; be given back. -1 = Chemistry holds nothing. 0 = VSV was already off by the player's
; choice: no visitor scenes at all until they switch it on in VSV's menu.
Float _vsvWas = -1.0
; Seconds until the next try. Counted down by the tick, so it means the same thing
; after a save and a restart (real-time stamps do not: papyrus-realtime-in-save).
Float _wait = 0.0
; Rapport took our pair; the cooldown starts when Rapport is free again.
Bool _sceneOurs = False

; ---- lifecycle ----------------------------------------------------------------

Event OnQuestInit()
	Self.Connect()
EndEvent

Event OnInit()
	Self.Connect()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	Self.Connect()
EndEvent

Function Connect()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	Self.Resolve()
	; A load is a new launch: Rapport has forgotten any scene in flight.
	_sceneOurs = False
	Self.CancelTimer(kTick)
	Self.StartTimer(kTickSeconds, kTick)
EndFunction

; THE default values. scripts/build-mcm.py reads the assignments below to write the
; MCM defaults, so change a default HERE and re-run it.
Function Defaults()
	bVisitors = True
EndFunction

Function LoadSettings()
	Self.Defaults()
	; Only when MCM read our settings.ini (Autonomy.LoadSettings says why).
	If Rapport:Core.ModSettingInt("Chemistry", "iDefaults:Meta", 0) == 1
		bVisitors = Rapport:Core.ModSettingBool("Chemistry", "bVisitors:Visitors", bVisitors)
	EndIf
EndFunction

; Plugins only change between loads, so once per load (and on the first start).
Function Resolve()
	_enabled = None
	_visitor = None
	If Game.IsPluginInstalled("VulgarVisitors2.esm")
		_enabled = Game.GetFormFromFile(0x00000805, "VulgarVisitors2.esm") as GlobalVariable
		_allowSettlers = Game.GetFormFromFile(0x00000801, "VulgarVisitors2.esm") as GlobalVariable
		_ff = Game.GetFormFromFile(0x00000806, "VulgarVisitors2.esm") as GlobalVariable
		_mm = Game.GetFormFromFile(0x0000080C, "VulgarVisitors2.esm") as GlobalVariable
		_nightOnly = Game.GetFormFromFile(0x0000080D, "VulgarVisitors2.esm") as GlobalVariable
		_indoorOnly = Game.GetFormFromFile(0x00000811, "VulgarVisitors2.esm") as GlobalVariable
		_cooldown = Game.GetFormFromFile(0x00000813, "VulgarVisitors2.esm") as GlobalVariable
		_settlersOnly = Game.GetFormFromFile(0x00000814, "VulgarVisitors2.esm") as GlobalVariable
		_allowSitting = Game.GetFormFromFile(0x00000815, "VulgarVisitors2.esm") as GlobalVariable
	EndIf
	; VisitorNPCKeyword, as VSV finds it: Settlement Visitors 2, else the first one.
	If Game.IsPluginInstalled("SettlementVisitors2.esm")
		_visitor = Game.GetFormFromFile(0x00000BFC, "SettlementVisitors2.esm") as Keyword
	EndIf
	If _visitor == None && Game.IsPluginInstalled("SettlementVisitors.esm")
		_visitor = Game.GetFormFromFile(0x00000C50, "SettlementVisitors.esm") as Keyword
	EndIf
	_aafBusy = None
	_aafLocked = None
	If Game.IsPluginInstalled("AAF.esm")
		_aafBusy = Game.GetFormFromFile(0x0000915A, "AAF.esm") as Keyword
		_aafLocked = Game.GetFormFromFile(0x00017CEA, "AAF.esm") as Keyword
	EndIf
	; Fallout4.esm, every id checked against the master (2026-11-09).
	_workshopParent = Game.GetFormFromFile(0x0002058E, "Fallout4.esm") as Quest
	_gameHour = Game.GetFormFromFile(0x00000038, "Fallout4.esm") as GlobalVariable
	_linkSandbox = Game.GetFormFromFile(0x0022B5A7, "Fallout4.esm") as Keyword
	_linkCenter = Game.GetFormFromFile(0x00038C0B, "Fallout4.esm") as Keyword
	_linkHome = Game.GetFormFromFile(0x0002058F, "Fallout4.esm") as Keyword
	_settlement = Game.GetFormFromFile(0x00083C9A, "Fallout4.esm") as Keyword
	_human = Game.GetFormFromFile(0x0002CB72, "Fallout4.esm") as Keyword
	_ghoul = Game.GetFormFromFile(0x000EAFB7, "Fallout4.esm") as Keyword
	_child = Game.GetFormFromFile(0x001157E8, "Fallout4.esm") as Keyword
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != kTick
		Return
	EndIf
	; The next tick first: whatever happens below, the clock survives.
	Self.StartTimer(kTickSeconds, kTick)
	If _enabled == None
		; No VSV: nothing to replace. Not a word in the log every 30 seconds.
		Return
	EndIf
	If Rapport:Core.ApiVersion() < iNeedsRapport
		; Autonomy says so once per load; not again here.
		Return
	EndIf
	Self.LoadSettings()
	Self.Govern()
	If !bVisitors || _vsvWas <= 0.0
		Return
	EndIf

	If _sceneOurs
		If Rapport:Core.Busy()
			Return
		EndIf
		_sceneOurs = False
		_wait = Self.CooldownSeconds()
		Rapport:Core.Trace("chemistry visitors: the scene is over; next try in " + (_wait as Int) + "s (VSV's cooldown)")
	EndIf
	If _wait > 0.0
		_wait -= kTickSeconds
		Return
	EndIf
	If Self.TryPair()
		Return
	EndIf
	_wait = kRetrySeconds
EndEvent

; Who pairs visitors: VSV's own script or this one. Re-checked every tick, so a
; player who switches VSV back on in its menu hands the pairing to Chemistry again
; rather than to VSV, while this option is on.
Function Govern()
	Float now = _enabled.GetValue()
	If bVisitors
		If now != 0.0
			_vsvWas = now
			_enabled.SetValue(0.0)
			Rapport:Core.Trace("chemistry visitors: Vulgar Settlers & Visitors' own pairing is off; Chemistry pairs its visitors and settlers through Rapport. Turning Chemistry's 'Visitor scenes' off gives it back.")
		ElseIf _vsvWas < 0.0
			_vsvWas = 0.0
			Rapport:Core.Trace("chemistry visitors: Vulgar Settlers & Visitors was already switched off, so no visitor scenes until it is switched on in its menu")
		EndIf
	ElseIf _vsvWas >= 0.0
		If now == 0.0 && _vsvWas > 0.0
			_enabled.SetValue(_vsvWas)
		EndIf
		_vsvWas = -1.0
		_sceneOurs = False
		_wait = 0.0
		Rapport:Core.Trace("chemistry visitors: 'Visitor scenes' is off - Vulgar Settlers & Visitors pairs its own visitors again")
	EndIf
EndFunction

Float Function CooldownSeconds()
	; VSV's slider is minutes of real time (it StartTimers value * 60).
	If _cooldown == None
		Return 300.0
	EndIf
	Return _cooldown.GetValue() * 60.0
EndFunction

Bool Function On(GlobalVariable akSwitch)
	Return akSwitch != None && akSwitch.GetValue() > 0.0
EndFunction

; ---- the pairing --------------------------------------------------------------

; True when Rapport took a pair.
Bool Function TryPair()
	Actor player = Game.GetPlayer()
	Location here = player.GetCurrentLocation()
	If here == None || _settlement == None || !here.HasKeyword(_settlement)
		Return False
	EndIf
	If Self.On(_nightOnly) && _gameHour != None
		Float hour = _gameHour.GetValue()
		If hour > 8.0 && hour < 20.0
			Return False
		EndIf
	EndIf
	If Rapport:Core.Busy() || Rapport:Core.PlayerHoldsSlot()
		Return False
	EndIf
	ObjectReference ws = Self.WorkshopHere(here)
	If ws == None
		Return False
	EndIf
	ObjectReference marker = ws.GetLinkedRef(_linkSandbox)
	If marker == None
		marker = ws.GetLinkedRef(_linkCenter)
	EndIf
	If marker == None
		Return False
	EndIf
	Actor[] people = marker.GetActorsLinkedToMe(_linkHome, None)
	If people == None || people.Length < 2
		Return False
	EndIf
	Int n = people.Length
	If n > 128
		n = 128
	EndIf

	; Shuffled, as VSV does: nobody is first in line every time.
	Int i = n - 1
	While i > 0
		Int k = Utility.RandomInt(0, i)
		Actor swap = people[i]
		people[i] = people[k]
		people[k] = swap
		i -= 1
	EndWhile

	Bool allowSettlers = Self.On(_allowSettlers)
	Bool settlersOnly = Self.On(_settlersOnly)
	Bool allowSitting = Self.On(_allowSitting)
	Bool indoorOnly = Self.On(_indoorOnly)
	Bool mm = Self.On(_mm)
	Bool ff = Self.On(_ff)

	Bool[] ok = new Bool[n]
	Int eligible = 0
	i = 0
	While i < n
		ok[i] = Self.Eligible(people[i], player, allowSettlers, settlersOnly, allowSitting, indoorOnly)
		If ok[i]
			eligible += 1
		EndIf
		i += 1
	EndWhile
	If eligible < 2
		Return False
	EndIf

	Int asks = 0
	i = 0
	While i < n && asks < kMaxAsks
		If ok[i]
			Actor a = people[i]
			Int sexA = a.GetLeveledActorBase().GetSex()
			Int j = 0
			While j < n && asks < kMaxAsks
				If j != i && ok[j]
					Actor b = people[j]
					If a.GetDistance(b) < kPartnerReach && Self.SexesAllowed(sexA, b.GetLeveledActorBase().GetSex(), mm, ff)
						asks += 1
						If Self.Ask(a, b)
							Return True
						EndIf
					EndIf
				EndIf
				j += 1
			EndWhile
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

; The workshop of this location, if the player owns it. WorkshopParentScript and
; WorkshopScript are not in the base sources this compiles against, so by name:
; one CallFunction and one property read, as VSV calls them.
ObjectReference Function WorkshopHere(Location akHere)
	If _workshopParent == None
		Return None
	EndIf
	ScriptObject wps = _workshopParent.CastAs("WorkshopParentScript")
	If wps == None
		Return None
	EndIf
	Var[] args = new Var[1]
	args[0] = akHere
	ObjectReference ws = wps.CallFunction("GetWorkshopFromLocation", args) as ObjectReference
	If ws == None
		Return None
	EndIf
	ScriptObject workshop = ws.CastAs("WorkshopScript")
	If workshop == None || !(workshop.GetPropertyValue("OwnedByPlayer") as Bool)
		Return None
	EndIf
	Return ws
EndFunction

Bool Function Eligible(Actor akWho, Actor akPlayer, Bool abAllowSettlers, Bool abSettlersOnly, Bool abAllowSitting, Bool abIndoorOnly)
	If akWho == None || akWho == akPlayer
		Return False
	EndIf
	If !akWho.Is3DLoaded() || akWho.IsDead() || akWho.IsUnconscious() || akWho.IsInScene()
		Return False
	EndIf
	If akWho.IsChild() || (_child != None && akWho.HasKeyword(_child))
		Return False
	EndIf
	If !akWho.HasKeyword(_human) && !akWho.HasKeyword(_ghoul)
		Return False
	EndIf
	If (_aafBusy != None && akWho.HasKeyword(_aafBusy)) || (_aafLocked != None && akWho.HasKeyword(_aafLocked))
		Return False
	EndIf
	If akWho.IsInDialogueWithPlayer()
		Return False
	EndIf
	Bool visitor = _visitor != None && akWho.HasKeyword(_visitor)
	If !visitor && !abAllowSettlers
		Return False
	EndIf
	If visitor && abSettlersOnly
		Return False
	EndIf
	; VSV lets a sitting VISITOR go; a sitting settler only with Allow Sitting.
	If !visitor && !abAllowSitting && akWho.GetSitState() != 0
		Return False
	EndIf
	If abIndoorOnly && !akWho.IsInInterior()
		Return False
	EndIf
	Return True
EndFunction

; VSV's switches as a filter. Rapport's orientation still decides who is willing.
Bool Function SexesAllowed(Int aiFirst, Int aiSecond, Bool abMM, Bool abFF)
	If aiFirst != aiSecond
		Return True
	EndIf
	If aiFirst == 0
		Return abMM
	EndIf
	If aiFirst == 1
		Return abFF
	EndIf
	Return False
EndFunction

Bool Function Ask(Actor akFirst, Actor akSecond)
	; Indoors stays put and takes its time; outside, Rapport walks them somewhere
	; out of sight when a crowd can see them (0.2.25).
	String scenario = "tender"
	If akFirst.IsInInterior()
		scenario = "athome"
	EndIf
	String who = Rapport:Core.ActorName(akFirst) + " + " + Rapport:Core.ActorName(akSecond)
	If Rapport:Core.CanRun(scenario, akFirst, akSecond) < 0
		Rapport:Core.Trace("chemistry visitors: no scenario named " + scenario + " - check Rapport's scenarios.json")
		Return False
	EndIf
	If Rapport:Core.RequestScene(akFirst, akSecond, scenario)
		_sceneOurs = True
		Rapport:Core.Trace("chemistry visitors: " + who + " (" + scenario + "), asked and Rapport took it")
		Return True
	EndIf
	Rapport:Core.Trace("chemistry visitors: " + who + " (" + scenario + "), Rapport declined: " + Rapport:Core.LastRefusal())
	Return False
EndFunction
