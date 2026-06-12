# The Verus bridge exploit was a missing invariant, not a missing line of code

**Draft, 2026-06-07. Status: internal — routes to §4a content-QA after §4b code gate passes.**

The bridge between Verus and Ethereum suffered an exploit on 2026-05-18 with reported losses of USD 11.58M (per Halborn's post-mortem; see *Sources*). Halborn's formal post-mortem and corroborating firm advisories from Blockaid and PeckShield have been published since (see *Sources* below). Halborn's post-mortem details the proximate mechanics; the advisories corroborate the incident. What they do not do — and what this companion repo does — is express the rule the bridge violated as a *machine-checkable invariant* that a fuzzer can hammer in CI.

The thesis of this note is narrow: the bridge's solvency rule was prose. It existed in the spec. It did not exist as code a checker could see. Lifting it to a checkable invariant is straightforward, and once lifted, the CI matrix asserts that a coverage-guided campaign (50,000 calls / 5 minutes) surfaces a counterexample on the planted-bug twin. The companion repo, `cf-invariants-verus-bridge-conservation`, ships that lift as a paired clean/planted reference.

We are not claiming the deployed code would have been bug-free if this invariant had been written. We are claiming something narrower and, we think, more useful: that **the class of defect the exploit revealed is the class of defect a one-line property test reliably catches**, and that the gap between "the spec says this must balance" and "the harness asserts this balances" is the gap the discipline closes.

## 1 — The rule, in one line

For every supported asset, the bridge's two-sided ledger must balance:

```
sum_locked_eth − sum_released_eth  ==  sum_minted_verus − sum_burned_verus
```

This is the conservation law. Any sequence of operations — lock, release, mint, burn, in any order, by any caller, under any reentrancy condition — must preserve it. Halborn's post-mortem describes the rule informally in its reconstruction section (framing: "supply equivalence across chains"). The framing matches; the name differs; the implementation does not lift the rule into a runtime check.

This note will not enumerate which exact lines of the deployed bridge were the failure site. Halborn's post-mortem covers that ground; we do not have the engagement to add anything there. What we have is a reference for what *enforcing* this rule looks like at the harness level.

## 2 — Why prose-only is not enough

Halborn's post-mortem and corroborating firm advisories from Blockaid and PeckShield cover this incident. Halborn's reconstruction reaches correct conclusions about the mechanics; the advisories are consistent with it. None of them ship a runnable test that, on every code change to a hypothetical replacement bridge, would re-prove that the conservation rule still holds.

That is the gap the audit discipline calls out. Trail of Bits' *Building Secure Smart Contracts* corpus and ChainSecurity's published findings both make the same observation in different words: the value of an invariant is not the moment you state it; it is the loop you wire it into so it gets re-checked on every subsequent change. A prose post-mortem teaches the reader the rule. It does not protect the next bridge from forgetting the rule.

The reproduction in this repo is not a forensic claim. It is a demonstration of what the loop costs to wire (one Solidity file for the contract, one for the property, one CI matrix) and what it catches (the planted twin breaks the invariant on a 5-minute campaign, asserted on every CI run).

## 3 — The reference

`MinimalBridge.sol` (clean) is the smallest contract that exposes the two settlement operations a lock/mint bridge needs: `bridgeIn` (lock ETH, mint wrapped Verus) and `bridgeOut` (burn wrapped Verus, release ETH). Each operation atomically advances both sides of the four-sum ledger the conservation rule reads. The conservation rule reads four storage slots and compares two differences. There is no business logic beyond this; the contract is short on purpose.

`PlantedBridge.sol` is the same contract with one defect injected. The defect is *a* shape the exploit class takes — a release path that updates the user-side balance but skips the protocol-side accounting. We have not claimed it is the specific shape of the deployed bug; we have written it as a representative member of the class.

The Chimera-pattern harness (`test/recon/`) wires both contracts into the same fuzzer surface. The single property — `INV-CONS-bridge-balance` — reads the four sums and asserts equality. The fuzzer rotates through three actors, calls the two operations under randomized inputs, and reports any sequence that produces a non-zero discrepancy.

## 4 — What the campaign produces

On `MinimalBridge.sol`, the campaign runs to its limit (50,000 calls / 5 minutes in CI) without surfacing a violation. The scorecard records `invariants_violated: 0`.

On `PlantedBridge.sol`, the campaign surfaces a counterexample well inside the campaign limit. The shrunk failing sequence is two calls — a `bridgeIn` followed by a `bridgeOut` that exposes the missed accounting update. The scorecard records `invariants_violated: 1`, includes the call sequence, and the deterministic reproduction is already scripted in the forge replay test (`CryticToFoundry.sol::test_planted_conservation_breaks_on_bridgeOut`).

The CI matrix asserts both outcomes. A green badge on the matrix means the clean leg held (the rule is enforceable) AND the planted leg broke (the fuzzer is doing its job). Either leg's failure mode is a regression and surfaces normally.

## 5 — How this is positioned

The register we are writing in is the Trail of Bits / ChainSecurity reference register: calm, dated, sourced. We are not ambulance-chasing. The incident has been public for three weeks; the published analyses have done the forensic work. We are adding one dimension that none of them has — a runnable expression of the invariant — because that dimension is the one that closes the loop the discipline cares about.

This is not a claim that the Verus team failed at a discipline anyone else has solved. The conservation-as-invariant pattern is rare across the bridge corpus generally. The point of the reference is to make it less rare by lowering the activation cost: the contract is under 90 lines including comments, the property is a one-line equality, the CI matrix is one additional `strategy.matrix` axis on top of a standard Chimera scaffold.

## 6 — Limitations

- **We model the class, not Verus's exact code.** Our `MinimalBridge.sol` is a minimal lock/mint bridge. The deployed Verus bridge has more surface area, more roles, and more cross-chain message-passing machinery. The conservation rule is general; the specific failure path in our planted twin is illustrative.
- **One invariant.** Pause-control, signer-set rotation, replay protection, and oracle-pricing classes are equally important and need separate harnesses. They are out of scope here. We may write companion references for them; this is not a commitment.
- **Fuzz coverage is not proof.** A coverage-guided campaign that finds 0 violations in 5 minutes is evidence the rule holds under that surface; it is not a proof. Symbolic execution or formal verification of the invariant is a separate dimension we have not added.
- **Citations are to public sources.** We have not contacted the Verus team and we have not seen any private incident-response material. If any of the cited analyses are subsequently revised, this note will be re-dated and the citation updated.

## 7 — How to read the companion repo

`README.md` walks the layout. The fastest path from clone to a violation counterexample is two `make` targets: `make clean-campaign` (expect zero) and `make planted-campaign` (expect one). Both legs run in CI on every push to `main` and on every pull request, under `.github/workflows/ci.yml`. The scorecard shape in `findings/INV-CONS-bridge-balance/scorecard.expected.md` is the artifact attached to contest entries that adopt this pattern.

## Sources

Cited in publication date order. Halborn's entry is the load-bearing formal post-mortem; Blockaid and PeckShield are firm advisories from their own channels.

- **Halborn**, "Explained: The Verus-Ethereum Bridge Hack (May 2026)," dated 2026-05-18 (page stamp). Framing: supply-equivalence failure across chains. URL: https://www.halborn.com/blog/post/explained-the-verus-ethereum-bridge-hack-may-2026
- **Blockaid**, X alert (exploit detection), 2026-05-18. Genre: firm advisory (X). URL: https://x.com/blockaid_/status/2056176541785034803
- **PeckShield**, X alert (drain reported), 2026-05-18. Genre: firm advisory (X). URL: https://x.com/PeckShieldAlert/status/2056194168385642881

Halborn's entry is the load-bearing source. Blockaid and PeckShield entries are firm advisories from their own channels, included for corroboration. If a further formal analysis is published before this draft ships externally, it will be added to the source list.

## Reference register

The general discipline this note draws from:

- **Trail of Bits**, *Building Secure Smart Contracts* (corpus). The "invariants-as-tests" pattern; the discipline of expressing what-must-be-true in code rather than prose.
- **ChainSecurity**, published findings library. The framing that an invariant's value comes from the loop it is wired into, not the moment it is stated.

Both references inform the angle of this note. Neither has published on the Verus incident specifically.

---

*2026-06-07 draft. Internal until §4a + §4b gates pass. Apache-2.0 on the companion repo.*
