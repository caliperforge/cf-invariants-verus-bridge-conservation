# AI-disclosure — cf-invariants-verus-bridge-conservation

This repo was authored with AI assistance under the CaliperForge AI-disclosure
register. Per CaliperForge policy, disclosure is made on repos where AI authored
substantive content; this repo qualifies.

## What AI did

- Authored the first-pass Solidity for `MinimalBridge.sol`, `PlantedBridge.sol`,
  and the Chimera harness (`Setup`, `BeforeAfter`, `TargetFunctions`,
  `Properties`, `CryticCleanTester`, `CryticPlantedTester`,
  `CryticToFoundry`) under the human author's direction.
- Drafted the writeup at `docs/writeup.md`, including the framing and the
  source citations. Halborn's formal post-mortem and firm advisories from
  Blockaid and PeckShield were used as the prose-source set; AI did not
  independently verify the underlying incident mechanics.
- Drafted the CI matrix workflow and the scorecard capture script.

## What AI did NOT do

- Did not consult any private Verus team incident-response material — the
  repo is built from the cited public analyses only.
- Did not synthesize any claim about which exact line of the deployed Verus
  bridge was the failure site. The planted defect is illustrative of the
  conservation-rule class, not a forensic claim about the deployed code.

## How to disable AI assistance in this repo

- The repo is reproducible end-to-end without AI involvement: the Foundry
  / Echidna toolchain runs the same campaigns regardless of authorship.
- A maintainer who wants to author follow-up invariants by hand can do so
  by editing `test/recon/Properties.sol` directly; no AI-only tooling
  exists in the build path.

## Provenance

Authored and reviewed by Michael Moffett, operator at CaliperForge. AI
assistance: Claude (Anthropic). Full policy at caliperforge.com/ai-disclosure.
