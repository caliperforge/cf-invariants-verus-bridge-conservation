// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CryticAsserts} from "chimera/CryticAsserts.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {Properties} from "./Properties.sol";
import {IBridge} from "../../src/IBridge.sol";
import {PlantedBridge} from "../../src/PlantedBridge.sol";

/// @notice CryticPlantedTester — fuzzer entry for the planted leg.
///
/// Echidna and Medusa point at this contract on the planted CI leg. Deploys
/// PlantedBridge and runs the conservation property against it. Expected
/// outcome: ≥1 violation surfaced within seconds, on a 2-call
/// `bridgeIn` → `bridgeOut` sequence.
contract CryticPlantedTester is TargetFunctions, Properties, CryticAsserts {
    constructor() payable {
        setup();
    }

    function _deployBridge() internal override returns (IBridge) {
        return IBridge(address(new PlantedBridge()));
    }
}
