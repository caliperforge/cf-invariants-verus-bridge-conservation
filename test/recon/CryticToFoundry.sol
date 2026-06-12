// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {CryticCleanTester} from "./CryticCleanTester.sol";
import {CryticPlantedTester} from "./CryticPlantedTester.sol";

/// @notice CryticToFoundry — forge-side replay + smoke test.
///
/// Runs in the build-and-smoke CI job to confirm:
///   1. Both testers compile and deploy cleanly.
///   2. The clean leg's invariant holds at the post-setup state.
///   3. The planted leg's invariant ALSO holds at post-setup (the defect
///      only triggers after a bridgeIn → bridgeOut sequence).
///   4. A scripted 2-call sequence on the planted tester surfaces the
///      counterexample under forge, with full -vvvv trace available for
///      debug. This is the deterministic reproduction the writeup cites.
contract CryticToFoundryTest is Test {
    CryticCleanTester internal cleanTester;
    CryticPlantedTester internal plantedTester;

    function setUp() public {
        cleanTester = new CryticCleanTester();
        plantedTester = new CryticPlantedTester();
    }

    /// @notice Smoke — both testers hold the conservation invariant at the
    /// post-setup state (no calls have been made yet, both sides are zero).
    function test_smoke_conservation_holds_at_setup() public view {
        assertTrue(
            cleanTester.property_conservation_INVCONS(),
            "clean: INV-CONS-bridge-balance violated at setup"
        );
        assertTrue(
            plantedTester.property_conservation_INVCONS(),
            "planted: INV-CONS-bridge-balance violated at setup (unexpected -- defect should only surface after bridgeOut)"
        );
    }

    /// @notice Clean: a bridgeIn → bridgeOut sequence preserves the
    /// conservation invariant.
    function test_clean_conservation_holds_through_full_cycle() public {
        cleanTester.target_bridgeIn(0, 100 ether);
        assertTrue(cleanTester.property_conservation_INVCONS(), "clean: violated after bridgeIn");
        cleanTester.target_bridgeOut(0, 100 ether);
        assertTrue(cleanTester.property_conservation_INVCONS(), "clean: violated after bridgeOut");
    }

    /// @notice Planted: the same sequence breaks the conservation
    /// invariant — the deterministic counterexample the writeup cites.
    function test_planted_conservation_breaks_on_bridgeOut() public {
        plantedTester.target_bridgeIn(0, 100 ether);
        assertTrue(
            plantedTester.property_conservation_INVCONS(),
            "planted: violated after bridgeIn (unexpected -- bridgeIn is symmetric)"
        );
        plantedTester.target_bridgeOut(0, 100 ether);
        assertFalse(
            plantedTester.property_conservation_INVCONS(),
            "planted: expected violation after bridgeOut (the planted defect) -- but property reports true"
        );
    }
}
