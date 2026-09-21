"""Generate Chemistry's MCM menu from the script that holds the defaults.

    python scripts/build-mcm.py

Writes data/MCM/Config/Chemistry/config.json (the pages) and settings.ini (what MCM
shows as the default). Every default is READ from Autonomy.psc's Defaults(), never
typed here, so the menu and the script's no-MCM behaviour cannot disagree. Re-run
after changing a default there.

Autonomy.psc reads these back every poll (LoadSettings) under the same ids.
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
        ("section", "General"),
        ("General", "bEnabled", "Autonomous scenes", "Off pauses Chemistry: nothing starts on its own, and "
         "Rapport's built-in trigger stays off too.", None, None, None),
        ("General", "fMinimumScore", "Score needed", "The total a pair must reach (Rapport's score plus "
         "Chemistry's bonuses). Lower means more scenes.", 0.0, 5.0, 0.05),
        ("General", "fCooldownHours", "Rest per person (game hours)", "After a scene, each of the two rests "
         "this long before another.", 0.0, 168.0, 1.0),
        ("General", "fPollSeconds", "Check every (s)", "How often Chemistry looks for a pair.", 5.0, 300.0, 5.0),
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
        ("section", "Refusals"),
        ("Refusals", "fRefusalBackoffHours", "Back off after a refusal (h)", "When AAF refuses someone, wait "
         "this long, doubling with each refusal.", 0.0, 24.0, 0.5),
        ("Refusals", "fRefusalBackoffCap", "Longest back-off (h)", "The doubling stops here.", 1.0, 168.0, 1.0),
    ]),
]

pages, ini, used = [], {}, set()
for title, rows in PAGES:
    content = []
    for row in rows:
        if row[0] in ("text", "section"):
            content.append({"type": row[0], "text": row[1]})
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

config = {"modName": "Chemistry", "displayName": "Chemistry", "minMcmVersion": 1,
          "pluginRequirements": ["Chemistry.esp"], "pages": pages}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "config.json").write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
lines = ["; GENERATED by scripts/build-mcm.py from Autonomy.psc Defaults() - edit that, not this."]
for section, keys in ini.items():
    lines.append(f"[{section}]")
    lines += [f"{k}={v}" for k, v in keys.items()]
    lines.append("")
(OUT / "settings.ini").write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {OUT / 'config.json'} and settings.ini: {len(used)} settings across {len(pages)} pages")
