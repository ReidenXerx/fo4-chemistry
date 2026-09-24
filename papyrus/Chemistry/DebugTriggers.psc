Scriptname Chemistry:DebugTriggers Hidden
{R-23 (owner poll, 2026-09-24): Chemistry's decision on demand, from the MCM's Debug
page and its hotkeys, instead of waiting for the next poll.

  REAL   the ordinary pass, now, with every gate; the HUD says what it came to.
  FORCED the best pair Rapport offers, under the bar, resting or backed off.

Global functions with no parameters, so MCM buttons and keybinds call them alike.}

Chemistry:Autonomy Function App() Global
	Return Game.GetFormFromFile(0x00000800, "Chemistry.esp") as Chemistry:Autonomy
EndFunction

Function Decide(Bool abForce) Global
	Chemistry:Autonomy app = Chemistry:DebugTriggers.App()
	String line = "Chemistry debug: Chemistry.esp's quest did not resolve"
	If app != None
		line = app.ConsiderNow(abForce)
	EndIf
	Debug.Notification(line)
	Rapport:Core.Trace("chemistry: " + line)
EndFunction

; ---- what the MCM calls -----------------------------------------------------
Function DecideNowForced() Global
	Chemistry:DebugTriggers.Decide(true)
EndFunction

Function DecideNowReal() Global
	Chemistry:DebugTriggers.Decide(false)
EndFunction
