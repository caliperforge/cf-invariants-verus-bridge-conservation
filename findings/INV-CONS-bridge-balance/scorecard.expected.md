# Scorecard — INV-CONS-bridge-balance (expected shape)

This file documents the scorecard shape `scripts/capture_scorecard.sh` writes
into `findings/INV-CONS-bridge-balance/<leg>/scorecard.{json,md}` on every
campaign. The paired matrix:

| Leg     | `invariants_violated` | Outcome     | CI assertion           |
|---------|----------------------:|-------------|------------------------|
| clean   | 0                     | expected    | fails if `!= 0`        |
| planted | ≥1                    | expected    | fails if `< 1`         |

## Expected `clean/scorecard.json`

```json
{
  "campaign": "echidna",
  "leg": "clean",
  "invariant": "INV-CONS-bridge-balance",
  "invariants_violated": 0,
  "tests_run": 50000,
  "captured_at": "<timestamp>",
  "expected_violations": 0,
  "outcome": "expected"
}
```

## Expected `planted/scorecard.json`

```json
{
  "campaign": "echidna",
  "leg": "planted",
  "invariant": "INV-CONS-bridge-balance",
  "invariants_violated": 1,
  "tests_run": "<varies — typically <100 before surface>",
  "captured_at": "<timestamp>",
  "expected_violations": 1,
  "outcome": "expected"
}
```

## Expected planted counterexample (shrunk)

The shrunk failing sequence is two calls, typically:

```
CryticPlantedTester.target_bridgeIn(0, <amount>)
CryticPlantedTester.target_bridgeOut(0, <amount>)
```

Both calls use the same actor index. After `target_bridgeOut`, the bridge's
`sumReleasedEth` has advanced but `sumBurnedVerus` has not — the equality
`sumLockedEth - sumReleasedEth == sumMintedVerus - sumBurnedVerus` fails.
