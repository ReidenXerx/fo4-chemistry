"""Generate Chemistry's MCM menu from the script that holds the defaults.

    python scripts/build-mcm.py

Writes data/MCM/Config/Chemistry/config.json (the pages) and settings.ini (what MCM
shows as the default). Every default is READ from Autonomy.psc's Defaults(), never
typed here, so the menu and the script's no-MCM behaviour cannot disagree. Re-run
after changing a default there.

Autonomy.psc reads these back every poll (LoadSettings) under the same ids, and only
when MCM has read THIS file: settings.ini carries [Meta] iDefaults=1, a key on no
control, and LoadSettings must test it -- checked below, or nothing is written.
Crowd tolerance is deliberately absent: Chemistry uses Rapport's (DESIGN C-6), and
it is on Rapport's page.
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "papyrus" / "Chemistry" / "Autonomy.psc"
OUT = ROOT / "data" / "MCM" / "Config" / "Chemistry"

source = SCRIPT.read_text(encoding="utf-8")
body = re.search(r"^Function Defaults\(\)\n(.*?)^EndFunction", source, re.M | re.S)
if not body:
    raise SystemExit("no Defaults() in Autonomy.psc - nothing to read the defaults from")
defaults = {}
for name, value in re.findall(r"^\s*(\w+) = (\S+)\s*$", body.group(1), re.M):
    defaults[name] = value

# (section, key, label, help, min, max, step) - step None = switch
PAGES = [
    ("Autonomy", [
        ("text", "Chemistry decides who pairs up and which scene plays, on top of Rapport's score. Crowd "
                 "tolerance is on Rapport's page: both mods use that one number."),
        ("section", "Starting"),
        ("button", "Start now", "Chemistry waits until you leave Vault 111. If an alternate start mod means it "
         "never started, press this: Chemistry, Rapport and the mods built on it start now, in this save. "
         "Needs Rapport 0.2.2.",
         {"type": "CallGlobalFunction", "script": "Rapport:Core", "function": "StartNow", "params": []}),
        ("section", "General"),
        ("General", "bEnabled", "Autonomous scenes", "Off pauses Chemistry: nothing starts on its own, and "
         "Rapport's built-in trigger stays off too.", None, None, None),
        ("General", "fMinimumScore", "Score needed", "The total a pair must reach (Rapport's score plus "
         "Chemistry's bonuses). Lower means more scenes.", 0.0, 5.0, 0.05),
        ("General", "fCooldownHours", "Rest per person (game hours)", "After a scene, each of the two rests "
         "this long before another.", 0.0, 168.0, 1.0),
        ("General", "fPollSeconds", "Check every (s)", "How often Chemistry looks for a pair. Not below 20: a pass can take seconds.", 20.0, 300.0, 5.0),
        ("General", "fNearMissMargin", "Near miss within", "How close to the bar a passed-over pair must be "
         "for the Narrator's 'why nothing happened' line.", 0.0, 2.0, 0.05),
        ("General", "iLogLevel", "Log detail", "0 only actions, 1 the full table when it acts, 2 the table "
         "every pass (Rapport.log).", 0, 2, 1),
        ("section", "Their place"),
        ("Place", "fOwnPlaceBonus", "Their own home", "Bonus when one of them lives here.", 0.0, 2.0, 0.05),
        ("Place", "fFactionPlaceBonus", "Their faction's place", "Bonus in a building their faction owns.",
         0.0, 2.0, 0.05),
    ]),
    ("Relationships", [
        ("section", "Bond"),
        ("Bond", "fBondWeight", "Bond weight", "How much a pair's bond (-1 to +1, Rapport's relationship "
         "store) adds to the score.", 0.0, 3.0, 0.05),
        ("Bond", "fBondCap", "Bond cap", "The most the bond can add or take away. Keeps one couple from "
         "owning a settlement.", 0.0, 2.0, 0.05),
        ("section", "Personas"),
        ("Personas", "fKindredBonus", "Same persona", "Bonus when both have the same persona.",
         0.0, 1.0, 0.05),
        ("Personas", "fClashPenalty", "Romantic with vulgar", "Penalty for a romantic and a vulgar pair.",
         0.0, 1.0, 0.05),
        ("Personas", "fAudienceBonus", "Vulgar likes an audience", "Bonus per vulgar member when a crowd is "
         "watching.", 0.0, 1.0, 0.05),
        ("Personas", "fShyPenalty", "Reticent shy of crowds", "Penalty per reticent member when a crowd is "
         "watching.", 0.0, 2.0, 0.05),
        ("Personas", "fFaithWeight", "Faithfulness weight", "Each NPC has a fixed faithfulness from 0 to 1. Pairing "
         "someone married or courting with anyone else costs this times it. 0 turns it off.", 0.0, 2.0, 0.05),
        ("Personas", "bLoverSpokenFor", "Your lover is spoken for", "Someone who is your lover (through Overture) "
         "pays the faithfulness cost with anyone else, and straying is recorded as an affair. Needs Rapport 0.2.1.",
         None, None, None),
        ("section", "Refusals"),
        ("Refusals", "fRefusalBackoffHours", "Back off after a refusal (h)", "When AAF refuses someone, wait "
         "this long, and this much longer again with each further refusal.", 0.0, 24.0, 0.5),
        ("Refusals", "fRefusalBackoffCap", "Longest back-off (h)", "The wait never grows past this.", 1.0, 168.0, 1.0),
    ]),
]

pages, ini, used = [], {}, set()
for title, rows in PAGES:
    content = []
    for row in rows:
        if row[0] in ("text", "section"):
            content.append({"type": row[0], "text": row[1]})
            continue
        if row[0] == "button":
            content.append({"type": "button", "text": row[1], "help": row[2], "action": row[3]})
            continue
        section, key, label, help_, lo, hi, step = row
        if key not in defaults:
            raise SystemExit(f"{key} has no default in Defaults() - the menu would invent one")
        used.add(key)
        raw = defaults[key]
        if step is None:
            ini.setdefault(section, {})[key] = "1" if raw == "True" else "0"
            content.append({"type": "switcher", "id": f"{key}:{section}", "text": label, "help": help_,
                            "valueOptions": {"sourceType": "ModSettingBool"}})
            continue
        integral = key.startswith("i")
        ini.setdefault(section, {})[key] = str(int(float(raw))) if integral else f"{float(raw):.6f}"
        content.append({"type": "slider", "id": f"{key}:{section}", "text": label, "help": help_,
                        "valueOptions": {"min": lo, "max": hi, "step": step,
                                         "sourceType": "ModSettingInt" if integral else "ModSettingFloat"}})
    pages.append({"pageDisplayName": title, "content": content})

missing = sorted(set(defaults) - used)
if missing:
    raise SystemExit(f"Defaults() sets {missing} but the menu does not expose them - add or drop them")

# The proof that MCM read this file: a key on no control, which no moved slider can
# fake. LoadSettings must test it; a guard that is only a comment does not count.
META_SECTION, META_KEY = "Meta", "iDefaults"
ini[META_SECTION] = {META_KEY: "1"}
load = re.search(r"^Function LoadSettings\(\)\n(.*?)^EndFunction", source, re.M | re.S)
code = "\n".join(line.split(";", 1)[0] for line in load.group(1).splitlines()) if load else ""
# Rapport's reader since 9b548d5 (MCM.GetModSetting* answered 0 on 3 loads of 4). Its default
# must be 0, or a missing file would read as "settings present".
if not re.search(r'Rapport:Core\.ModSettingInt\("Chemistry",\s*"iDefaults:Meta",\s*0\)\s*!=\s*1', code):
    raise SystemExit('Autonomy.LoadSettings does not test Rapport:Core.ModSettingInt("Chemistry", "iDefaults:Meta", 0) != 1')

# R-23 (owner poll, 2026-09-24): the decision on demand, twice -- REAL is the ordinary
# pass now, FORCED the best pair Rapport offers -- as buttons and as hotkeys. The
# functions are papyrus/Chemistry/DebugTriggers.psc's parameterless globals.
DEBUG_SCRIPT = "Chemistry:DebugTriggers"
DEBUG = [
    # (function, button text, hotkey text, help)
    ("DecideNowForced", "Decide now - FORCED", "Decide now - forced",
     "Chemistry's decision this instant: the best pair Rapport offers, even under the bar, resting or "
     "backed off. Still waits for a running scene and the player's held slot."),
    ("DecideNowReal", "Decide now - REAL", "Decide now - real",
     "The ordinary pass, now instead of at the next poll, with every rule. The HUD says what it came to."),
]
debug = [{"type": "text", "text": "Chemistry's decision on demand, for testing: who pairs up and which scene plays, "
                                  "chosen now. FORCED skips the bar, resting and backing off; REAL is exactly the "
                                  "pass the timer runs."},
         {"type": "section", "text": "Decide"}]
for function, text, _, help_ in DEBUG:
    debug.append({"type": "button", "text": text, "help": help_,
                  "action": {"type": "CallGlobalFunction", "script": DEBUG_SCRIPT, "function": function, "params": []}})
debug.append({"type": "section", "text": "Hotkeys"})
for function, _, hotkey, help_ in DEBUG:
    debug.append({"id": "Chemistry" + function, "text": hotkey, "type": "hotkey", "help": help_})
pages.append({"pageDisplayName": "Debug", "content": debug})

config = {"modName": "Chemistry", "displayName": "Chemistry", "minMcmVersion": 1,
          "pluginRequirements": ["Chemistry.esp"], "pages": pages}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "config.json").write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
keybinds = {"modName": "Chemistry",
            "keybinds": [{"id": "Chemistry" + function, "desc": "Chemistry debug: " + hotkey,
                          "action": {"type": "CallGlobalFunction", "script": DEBUG_SCRIPT, "function": function}}
                         for function, _, hotkey, _ in DEBUG]}
(OUT / "keybinds.json").write_text(json.dumps(keybinds, indent=2) + "\n", encoding="utf-8")
lines = ["; GENERATED by scripts/build-mcm.py from Autonomy.psc Defaults() - edit that, not this."]
for section, keys in ini.items():
    lines.append(f"[{section}]")
    lines += [f"{k}={v}" for k, v in keys.items()]
    lines.append("")
(OUT / "settings.ini").write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {OUT / 'config.json'} and settings.ini: {len(used)} settings across {len(pages)} pages")
