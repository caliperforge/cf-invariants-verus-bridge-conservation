// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {BeforeAfter} from "./BeforeAfter.sol";

/// @notice Properties — INV-CONS-bridge-balance, the cross-side conservation invariant.
///
/// The single property this harness checks:
///
///     sumLockedEth - sumReleasedEth  ==  sumMintedVerus - sumBurnedVerus
///
/// In the clean leg (MinimalBridge), this holds at every reachable state and
/// the campaign reports zero violations. In the planted leg (PlantedBridge),
/// the first `bridgeOut` following any `bridgeIn` advances `sumReleasedEth`
/// without advancing `sumBurnedVerus` — the equality breaks and the fuzzer
/// emits a counterexample.
///
/// Scope: ONLY the cross-side conservation class. Pause-control, signer-set
/// rotation, replay protection, oracle pricing — all out of scope here.
abstract contract Properties is BeforeAfter {
    /// @notice The conservation rule. Returns true iff both sides balance.
    ///
    /// We read directly from the bridge's view rather than computing from
    /// the snapshot so the rule is checked against the same source the
    /// production code would expose to a downstream auditor.
    function property_conservation_INVCONS() public view returns (bool) {
        return bridge.conservationHolds();
    }

    /// @notice Echidna / Medusa entrypoint. Both engines pick up functions
    /// prefixed `echidna_` returning bool. The Chimera Asserts helper logs
    /// the property name on failure.
    function echidna_INVCONS_bridge_balance() public view returns (bool) {
        return property_conservation_INVCONS();
    }
}
