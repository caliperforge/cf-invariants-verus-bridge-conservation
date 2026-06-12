// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Setup} from "./Setup.sol";

/// @notice BeforeAfter — snapshots the four cross-side ledger sums.
///
/// The conservation rule reads the four sums directly. We snapshot for
/// completeness — a future variant may add monotonicity properties
/// ("sumLockedEth never decreases", etc.) that need both states. For the
/// current INV-CONS-bridge-balance property, only the post-call state is
/// strictly required.
abstract contract BeforeAfter is Setup {
    struct Vars {
        uint256 sumLockedEth;
        uint256 sumReleasedEth;
        uint256 sumMintedVerus;
        uint256 sumBurnedVerus;
    }

    Vars internal _before;
    Vars internal _after;

    function __snapshot() internal {
        _before = _readVars();
    }

    function __after() internal {
        _after = _readVars();
    }

    function _readVars() internal view returns (Vars memory v) {
        v.sumLockedEth = bridge.sumLockedEth();
        v.sumReleasedEth = bridge.sumReleasedEth();
        v.sumMintedVerus = bridge.sumMintedVerus();
        v.sumBurnedVerus = bridge.sumBurnedVerus();
    }
}
