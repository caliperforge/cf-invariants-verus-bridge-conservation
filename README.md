# cf-invariants-verus-bridge-conservation

**Status:** internal draft — repository is PRIVATE until §4b code-quality and §4a content gates pass. Do not link externally.

**Subject:** Verus–Ethereum bridge exploit, 2026-05-18, reported losses of USD 11.58M (per Halborn's post-mortem, cited in `docs/writeup.md`). Class: **cross-side conservation** — the bridge's both-sides-must-balance business rule existed in prose and spec but was never expressed as a machine-checkable invariant.

**What this repo is:** a runnable, CI-verified reference reproduction of the *invariant class*. Two EVM contracts — a clean reference (`MinimalBridge.sol`) and a planted-bug twin (`PlantedBridge.sol`) — drive a Chimera-pattern fuzz campaign over a single conservation property. The clean side returns 0 violations; the planted side returns ≥1. The paired result is the artifact.

**What this repo is not:** a port of Verus's production code, a forensic incident report, or an "audit" of the bridge. The published analyses (Halborn's formal post-mortem and corroborating firm advisories from Blockaid and PeckShield; cited in `docs/writeup.md`) cover the forensic angle in prose. This repo adds the dimension none of them have: a machine-checkable expression of the rule whose absence the exploit revealed.

## The invariant — one sentence

`INV-CONS-bridge-balance`: for every supported asset, `sum_locked_eth − sum_released_eth == sum_minted_verus − sum_burned_verus`. Any state transition that breaks this equality breaks the bridge's solvency.

The rule is prose in the spec. It is not (and was not) enforced at any code boundary that a fuzzer or static checker can see. This repo is what lifting that rule to a checkable invariant looks like.

## Layout

```
cf-invariants-verus-bridge-conservation/
├── LICENSE                                # Apache-2.0
├── README.md                              # this file
├── foundry.toml                           # solc 0.8.28, forge config
├── remappings.txt
├── echidna-clean.yaml / echidna-planted.yaml   # per-leg fuzz campaign configs
├── Makefile                               # make {clean,planted}-campaign
├── src/
│   ├── IBridge.sol                        # shared surface both bridges implement
│   ├── MinimalBridge.sol                  # clean reference — conservation holds
│   └── PlantedBridge.sol                  # planted-bug twin — conservation breaks
├── test/recon/
│   ├── Setup.sol                          # abstract; tester variants override `_deployBridge()`
│   ├── TargetFunctions.sol                # bridgeIn / bridgeOut surface
│   ├── BeforeAfter.sol                    # snapshot ledger sums
│   ├── Properties.sol                     # INV-CONS-bridge-balance
│   ├── CryticCleanTester.sol / CryticPlantedTester.sol   # fuzzer entries (clean / planted)
│   └── CryticToFoundry.sol                # forge-side replay + smoke
├── findings/INV-CONS-bridge-balance/
│   └── scorecard.expected.md              # shape captured per campaign
├── scripts/
│   └── capture_scorecard.sh               # ANSI-strip + JSON/MD renderer
├── docs/
│   ├── writeup.md                         # the §4a-bound draft (sourced)
│   └── ai-disclosure.md                   # what AI did, how to disable
└── .github/workflows/ci.yml               # matrix: leg ∈ {clean, planted}
```

## Paired-CI matrix (the artifact)

The CI job is a `strategy.matrix` over `leg ∈ {clean, planted}`. Each leg runs the same Echidna campaign against the same harness; only the concrete tester changes — `CryticCleanTester` deploys `MinimalBridge`, `CryticPlantedTester` deploys `PlantedBridge`. The expected outcome:

| leg       | `invariants_violated` | CI status |
|-----------|----------------------:|-----------|
| `clean`   | 0                     | green     |
| `planted` | ≥1 (counterexample emitted) | green (CI asserts the violation appears) |

Both legs are *expected* to be green — green on the clean leg means the rule holds, green on the planted leg means the fuzzer caught the bug. A failure on either leg is a real regression.

## Reproduce locally

```sh
git clone <this repo>
cd cf-invariants-verus-bridge-conservation

curl -L https://foundry.paradigm.xyz | bash && foundryup
# Echidna: https://github.com/crytic/echidna/releases (v2.2.5)

forge install foundry-rs/forge-std@v1.9.4
forge install Recon-Fuzz/chimera@463c0d4134931de315234be94eb21f1f032ea138

make clean-campaign      # expect: 0 violations
make planted-campaign    # expect: INV-CONS-bridge-balance violated, counterexample emitted
```

## Honest limitations

- **We model the class, not Verus's exact code.** The published analyses inspected the actual deployed contracts; we did not. The exploit class is reproducible without that fidelity — the rule the bridge violated is general to lock/mint bridges, not specific to one implementation.
- **The planted twin is illustrative, not forensic.** The defect we inject is *a* shape the exploit class takes (skipped accounting on a release path). It is not a claim about which exact line the real bridge mis-handled.
- **One invariant, not a kitchen sink.** Scope is deliberately the conservation class. Pause-control, signer-set rotation, replay protection, and oracle-pricing classes are different invariants that need different harnesses — out of scope for this repo.

## License

Apache-2.0 — see [`LICENSE`](./LICENSE).

## Provenance

This scaffold was built with AI assistance. Authored and reviewed by Michael Moffett, operator at CaliperForge. Full policy at caliperforge.com/ai-disclosure (see also [`docs/ai-disclosure.md`](./docs/ai-disclosure.md)).
