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
