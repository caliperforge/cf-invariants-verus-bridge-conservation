// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CryticAsserts} from "chimera/CryticAsserts.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {Properties} from "./Properties.sol";
import {IBridge} from "../../src/IBridge.sol";
import {MinimalBridge} from "../../src/MinimalBridge.sol";

/// @notice CryticCleanTester — fuzzer entry for the clean leg.
///
/// Echidna and Medusa point at this contract on the clean CI leg. Deploys
/// MinimalBridge and runs the conservation property against it. Expected
/// outcome: 0 violations.
contract CryticCleanTester is TargetFunctions, Properties, CryticAsserts {
    constructor() payable {
        setup();
    }

    function _deployBridge() internal override returns (IBridge) {
        return IBridge(address(new MinimalBridge()));
    }
}
