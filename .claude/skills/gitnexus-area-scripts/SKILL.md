---
name: gitnexus-area-scripts
description: "Skill for the Scripts area of fo4-chemistry. 55 symbols across 7 files."
---

# Scripts

55 symbols | 7 files | Cohesion: 86%

## When to Use

- Working with code in `scripts/`
- Understanding how verifyInstall, answered, code_lines work
- Modifying scripts-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `scripts/bearing-verify.mjs` | checkFile, checkManifest, checkPackageGates, checkRetiredHookKeys, checkSkillsStore (+13) |
| `scripts/bearing-ci.mjs` | blastRadius, collectDiff, detectChanges, num, git (+9) |
| `scripts/bearing-token-benchmark.mjs` | answered, classicalCost, cypher, gn, graphCost (+2) |
| `scripts/loc.py` | code_lines, count, human, main, tracked |
| `scripts/bearing-agent.mjs` | currentBranch, git, resolveBaseRef, run, runAllowFail |
| `scripts/strip-pex.py` | main, pack_str, read_str, strip |
| `scripts/release-nexus.mjs` | fail, readApiKey |

## Entry Points

Start here when exploring this area:

- **`verifyInstall`** (Function) — `scripts/bearing-verify.mjs:367`
- **`answered`** (Function) — `scripts/bearing-token-benchmark.mjs:163`
- **`code_lines`** (Function) — `scripts/loc.py:71`
- **`count`** (Function) — `scripts/loc.py:126`
- **`human`** (Function) — `scripts/loc.py:139`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `verifyInstall` | Function | `scripts/bearing-verify.mjs` | 367 |
| `answered` | Function | `scripts/bearing-token-benchmark.mjs` | 163 |
| `code_lines` | Function | `scripts/loc.py` | 71 |
| `count` | Function | `scripts/loc.py` | 126 |
| `human` | Function | `scripts/loc.py` | 139 |
| `main` | Function | `scripts/loc.py` | 143 |
| `tracked` | Function | `scripts/loc.py` | 57 |
| `main` | Function | `scripts/strip-pex.py` | 51 |
| `pack_str` | Function | `scripts/strip-pex.py` | 30 |
| `read_str` | Function | `scripts/strip-pex.py` | 25 |
| `strip` | Function | `scripts/strip-pex.py` | 34 |
| `blastRadius` | Function | `scripts/bearing-ci.mjs` | 110 |
| `collectDiff` | Function | `scripts/bearing-ci.mjs` | 78 |
| `detectChanges` | Function | `scripts/bearing-ci.mjs` | 92 |
| `num` | Function | `scripts/bearing-ci.mjs` | 95 |
| `git` | Function | `scripts/bearing-ci.mjs` | 49 |
| `gn` | Function | `scripts/bearing-ci.mjs` | 57 |
| `main` | Function | `scripts/bearing-ci.mjs` | 331 |
| `postSticky` | Function | `scripts/bearing-ci.mjs` | 299 |
| `repoName` | Function | `scripts/bearing-ci.mjs` | 73 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `Main → RuntimeSet` | cross_community | 4 |
| `Main → ReadStealth` | cross_community | 4 |
| `Main → Git` | intra_community | 3 |
| `Main → Num` | intra_community | 3 |
| `Main → Gn` | intra_community | 3 |
| `PickTargets → Gn` | intra_community | 3 |
| `Main → Run` | intra_community | 3 |
| `Main → CheckManifest` | cross_community | 3 |
| `Main → CheckSkillsStore` | cross_community | 3 |
| `Main → ReadRuntime` | cross_community | 3 |

## How to Explore

1. `context({name: "verifyInstall"})` — see callers and callees
2. `query({search_query: "scripts"})` — find related execution flows
3. Read key files listed above for implementation details
4. `explain({target: "<file or symbol>"})` — persisted taint findings (source→sink data flows), when indexed with `--pdg`
