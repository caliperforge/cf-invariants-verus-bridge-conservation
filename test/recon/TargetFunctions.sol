// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {BaseTargetFunctions} from "chimera/BaseTargetFunctions.sol";
import {vm} from "chimera/Hevm.sol";
import {Setup} from "./Setup.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

/// @notice TargetFunctions — public surface the fuzzer mutates.
///
/// Two operations: bridgeIn (caller deposits ETH, gets wrapped Verus) and
/// bridgeOut (caller burns wrapped Verus, gets ETH back). The actor rotation
/// cycles msg.sender across three addresses so the fuzzer can mix flows
/// from multiple users — that surfaces cross-actor bookkeeping bugs the
/// single-actor case would miss.
///
/// The amounts are bounded by a per-actor cap so the fuzzer doesn't drift
/// into uint256 overflow territory — overflow is its own catastrophic event
/// and not the conservation class we are targeting here.
abstract contract TargetFunctions is BaseTargetFunctions, BeforeAfter {
    // Per-actor cap on a single call's amount. Chosen so a campaign of
    // 50K calls cannot saturate uint256 sums even at worst-case allocation.
    uint256 internal constant AMOUNT_CAP = 1e30;

    function _actor(uint8 actorIdx) internal pure returns (address) {
        return _actors()[actorIdx % _actors().length];
    }

    function target_bridgeIn(uint8 actorIdx, uint256 amount) external {
        __snapshot();
        uint256 bounded = amount % AMOUNT_CAP;
        // prank applies to the *next* call only, so issue it immediately
        // before the mutating call — the __snapshot()/__after() view calls
        // above would otherwise consume it (the bug the §4b gate caught).
        vm.prank(_actor(actorIdx));
        bridge.bridgeIn(bounded);
        __after();
    }

    function target_bridgeOut(uint8 actorIdx, uint256 amount) external {
        __snapshot();
        address a = _actor(actorIdx);
        uint256 available = bridge.wrappedVerusBalance(a);
        if (available == 0) return; // nothing to burn; skip the call
        uint256 bounded = (amount % available) + 1;
        vm.prank(a);
        bridge.bridgeOut(bounded);
        __after();
    }
}
