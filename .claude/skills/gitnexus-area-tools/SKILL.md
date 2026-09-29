---
name: gitnexus-area-tools
description: "Skill for the Tools area of fo4-chemistry. 13 symbols across 2 files."
---

# Tools

13 symbols | 2 files | Cohesion: 100%

## When to Use

- Working with code in `tools/`
- Understanding how build, field, group work
- Modifying tools-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `tools/make_esp.py` | build, field, group, main, record (+2) |
| `tools/read_esp.py` | parse, prop_value, i16, u16, u8 (+1) |

## Entry Points

Start here when exploring this area:

- **`build`** (Function) — `tools/make_esp.py:69`
- **`field`** (Function) — `tools/make_esp.py:36`
- **`group`** (Function) — `tools/make_esp.py:59`
- **`main`** (Function) — `tools/make_esp.py:110`
- **`record`** (Function) — `tools/make_esp.py:51`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `build` | Function | `tools/make_esp.py` | 69 |
| `field` | Function | `tools/make_esp.py` | 36 |
| `group` | Function | `tools/make_esp.py` | 59 |
| `main` | Function | `tools/make_esp.py` | 110 |
| `record` | Function | `tools/make_esp.py` | 51 |
| `wstring` | Function | `tools/make_esp.py` | 46 |
| `zstring` | Function | `tools/make_esp.py` | 42 |
| `parse` | Function | `tools/read_esp.py` | 69 |
| `prop_value` | Function | `tools/read_esp.py` | 42 |
| `i16` | Method | `tools/read_esp.py` | 15 |
| `u16` | Method | `tools/read_esp.py` | 20 |
| `u8` | Method | `tools/read_esp.py` | 10 |
| `ws` | Method | `tools/read_esp.py` | 35 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `Main → Field` | intra_community | 3 |
| `Main → Record` | intra_community | 3 |
| `Main → Wstring` | intra_community | 3 |
| `Main → Zstring` | intra_community | 3 |
| `Parse → U16` | intra_community | 3 |

## How to Explore

1. `context({name: "build"})` — see callers and callees
2. `query({search_query: "tools"})` — find related execution flows
3. Read key files listed above for implementation details
4. `explain({target: "<file or symbol>"})` — persisted taint findings (source→sink data flows), when indexed with `--pdg`
