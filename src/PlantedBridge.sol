// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

/// @notice PlantedBridge — same surface as MinimalBridge with one planted
/// defect in the cross-side conservation accounting.
///
/// The planted shape: `bridgeOut` releases ETH and decrements the caller's
/// wrapped-Verus balance, but FAILS to advance `sumBurnedVerus`. The two
/// ledger sides drift the moment the first `bridgeOut` call lands: the
/// Ethereum side records the release, the Verus side does not record the
/// matching burn, and the conservation rule
///
///     sumLockedEth - sumReleasedEth  ==  sumMintedVerus - sumBurnedVerus
///
/// breaks.
///
/// This is *a* shape the conservation-class defect can take: forgetting to
/// advance one of two paired-state counters on a settlement path. It is not
/// a claim about which exact line of the deployed Verus bridge was the
/// failure site. Halborn's post-mortem and firm advisories from
/// Blockaid and PeckShield (both 2026-05-18) describe analogous shapes —
/// one side's accounting advancing without the matching update on the other
/// side — under different specific mechanics.
///
/// Acceptance criterion: a chimera-pattern campaign over this contract
/// surfaces a counterexample to `INV-CONS-bridge-balance` within
/// ~5 minutes / 50K calls. In practice we expect the violation in 2 calls:
/// one `bridgeIn` followed by one `bridgeOut`.
contract PlantedBridge {
    uint256 public sumLockedEth;
    uint256 public sumReleasedEth;
    uint256 public sumMintedVerus;
    uint256 public sumBurnedVerus;

    mapping(address => uint256) public wrappedVerusBalance;

    event BridgedIn(address indexed user, uint256 amount);
    event BridgedOut(address indexed user, uint256 amount);

    function bridgeIn(uint256 amount) external {
        sumLockedEth += amount;
        sumMintedVerus += amount;
        wrappedVerusBalance[msg.sender] += amount;
        emit BridgedIn(msg.sender, amount);
    }

    /// @notice PLANTED DEFECT.
    ///
    /// The clean reference (`MinimalBridge.bridgeOut`) advances `sumBurnedVerus`
    /// in lock-step with `sumReleasedEth` because the burn and release are
    /// two halves of the same cross-side settlement. This implementation
    /// drops the `sumBurnedVerus += amount;` line. The release-side ledger
    /// advances; the burn-side does not. The conservation rule breaks on
    /// the first call.
    function bridgeOut(uint256 amount) external {
        require(wrappedVerusBalance[msg.sender] >= amount, "PlantedBridge: insufficient wrapped");
        wrappedVerusBalance[msg.sender] -= amount;
        // PLANTED: missing `sumBurnedVerus += amount;` — the paired update
        // the clean reference performs. The fuzzer's INV-CONS-bridge-balance
        // property catches the drift on the first bridgeOut following any
        // bridgeIn.
        sumReleasedEth += amount;
        emit BridgedOut(msg.sender, amount);
    }

    function conservationHolds() external view returns (bool) {
        return sumLockedEth - sumReleasedEth == sumMintedVerus - sumBurnedVerus;
    }
}
