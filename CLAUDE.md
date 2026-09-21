# Agent notes

## Nexus Mods — always use `nexus-tools`

Anything that touches a Nexus page (description, changelog, version, screenshots) goes through
**`Projects/nexus-tools`**, never a hand-rolled browser driver.

```bash
node ../nexus-tools/src/cli.mjs desc-get fallout4 <modId>
node ../nexus-tools/src/cli.mjs desc-set fallout4 <modId> <file.bbcode> --save
node ../nexus-tools/src/cli.mjs shot <url> <out.png>
```

It attaches over CDP to the owner's already-running Brave (port 9222), so the session is reused and
nothing logs in. Own tab, never `document.cookie` or any credential field, and **it never clicks
Publish or Delete** — that stays the owner's click.

**Why this rule exists.** A hand-rolled CDP driver spent four attempts writing a description into a
`display:none` textarea and reported success every time. The editor is **SCEditor**, with three
surfaces and only one that works:

| surface | what happens |
| --- | --- |
| `.bbcode-editor > textarea` | `display:none`, empty on load — writing does nothing |
| the WYSIWYG iframe | BBCode goes in as **literal text**; the form still submits the old value |
| `.sceditor-button-source` | a real textarea of raw BBCode — **the only door** |

Also: `/edit/description` is a **404** (it lives on `/edit/general`), and the editor hydrates well
after `networkidle`. `desc-set` refuses to save unless what the editor holds matches the file.

## Publishing to Nexus — read `nexus-tools/docs/TRUST-PIPELINE.md` FIRST

**Read `nexus-tools/CLAUDE.md` before starting** (`AGENTS.md` there for other agents): the rules
every Nexus job follows, the badge/diagram generators, and the scars. Private repo:
https://github.com/ReidenXerx/nexus-tools — clone it next to this project if it is missing.

Anything touching a mod page, a release, or the question *"how do I know this is not
malware"* follows the numbered `T-#` rules there. Three of them exist because the obvious
move is wrong:

- **`T-3` — the CI hash does NOT match the shipped file.** Measured: same size, 83% of
  bytes different, because a different MSVC toolset generates different code. Never tell a
  user to verify their download against a build log until the release actually ships the CI
  artifact.
- **`T-4` — a VirusTotal lookup is free; an upload is permanent and public.** Link a scan
  only at zero detections, and renew it per release: every build has a new hash.
- **`T-1` — public source is necessary and not sufficient.** Nobody can tell by reading a
  repo whether the binary on the page came from it.
