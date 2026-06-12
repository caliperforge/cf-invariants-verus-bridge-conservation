// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {BaseSetup} from "chimera/BaseSetup.sol";
import {vm} from "chimera/Hevm.sol";
import {IBridge} from "../../src/IBridge.sol";

/// @notice Setup — deploys a bridge under the IBridge interface + registers actors.
///
/// Abstract: the concrete CryticTester variants override `_deployBridge()` to
/// pick MinimalBridge (clean leg) or PlantedBridge (planted leg). The rest of
/// the harness — TargetFunctions, BeforeAfter, Properties — is identical
/// across legs.
abstract contract Setup is BaseSetup {
    address internal constant ACTOR_ALICE = address(0x10000);
    address internal constant ACTOR_BOB = address(0x20000);
    address internal constant ACTOR_CAROL = address(0x30000);

    IBridge internal bridge;

    /// @notice Override in concrete tester to choose MinimalBridge or PlantedBridge.
    function _deployBridge() internal virtual returns (IBridge);

    function setup() internal virtual override {
        bridge = _deployBridge();
        vm.warp(1_700_000_000);
        vm.roll(18_000_000);
    }

    function _actors() internal pure returns (address[3] memory) {
        return [ACTOR_ALICE, ACTOR_BOB, ACTOR_CAROL];
    }
}
