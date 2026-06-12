// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

/// @notice MinimalBridge — clean reference modeling a lock/mint bridge's
/// cross-side conservation rule.
///
/// The conservation law (INV-CONS-bridge-balance):
///
///     sum_locked_eth - sum_released_eth  ==  sum_minted_verus - sum_burned_verus
///
/// Read as: "the net ETH held in custody on the Ethereum side equals the net
/// wrapped-Verus outstanding on the destination side, at every state." The
/// rule is the bridge's solvency definition: if it does not hold, the bridge
/// has either over-issued wrapped tokens against its escrow, or paid out more
/// ETH than was redeemed.
///
/// Real bridges encode this rule across separate Ethereum-side and Verus-side
/// transactions tied by cross-chain messaging. We collapse the two halves
/// into atomic operations on a single contract so the invariant is
/// strictly-true at every state — the model preserves the rule the
/// production bridge expresses across multiple transactions.
///
/// Two operations:
///   - `bridgeIn`: caller deposits ETH on Ethereum; contract issues an
///     equal amount of wrapped Verus to the caller. Both sums advance.
///   - `bridgeOut`: caller burns wrapped Verus; contract releases the
///     matching ETH. Both sums advance.
///
/// We deliberately do not model: signer-set rotation, replay protection, fee
/// accounting, pausability, oracle pricing, cross-chain messaging delay.
/// Those are different invariant classes and out of scope for the
/// conservation reference.
contract MinimalBridge {
    // -------------------------------------------------------------------------
    // Cross-side ledger — the four sums the conservation rule reads.
    // -------------------------------------------------------------------------
    uint256 public sumLockedEth;
    uint256 public sumReleasedEth;
    uint256 public sumMintedVerus;
    uint256 public sumBurnedVerus;

    // Per-actor wrapped-Verus balance — needed so `bridgeOut` can verify the
    // caller actually holds the wrapped tokens they want to burn.
    mapping(address => uint256) public wrappedVerusBalance;

    event BridgedIn(address indexed user, uint256 amount);
    event BridgedOut(address indexed user, uint256 amount);

    /// @notice Caller deposits ETH on the Ethereum side; the contract atomically
    /// records the lock AND issues the matching wrapped-Verus balance.
    ///
    /// (We model the ETH transfer as a uint256 amount rather than msg.value to
    /// keep the harness state-only — fuzzer inputs are amounts, not transfers.)
    function bridgeIn(uint256 amount) external {
        sumLockedEth += amount;
        sumMintedVerus += amount;
        wrappedVerusBalance[msg.sender] += amount;
        emit BridgedIn(msg.sender, amount);
    }

    /// @notice Caller burns wrapped Verus from their balance; the contract
    /// atomically records the burn AND releases the matching ETH.
    ///
    /// WHY the burn and release advance together: this is the line that
    /// PlantedBridge.sol breaks. Releasing ETH without advancing the burn
    /// counter is precisely the cross-side conservation defect — one side's
    /// ledger moves, the other side's does not, the bridge silently becomes
    /// insolvent.
    function bridgeOut(uint256 amount) external {
        require(wrappedVerusBalance[msg.sender] >= amount, "MinimalBridge: insufficient wrapped");
        wrappedVerusBalance[msg.sender] -= amount;
        sumBurnedVerus += amount;
        sumReleasedEth += amount;
        emit BridgedOut(msg.sender, amount);
    }

    /// @notice Returns true iff the conservation rule holds at the current state.
    /// In the clean reference this is true at every reachable state; the
    /// Properties.sol harness asserts it after every fuzzer call.
    function conservationHolds() external view returns (bool) {
        // Both sides are non-negative by construction (sumReleased <= sumLocked
        // and sumBurned <= sumMinted in this contract's call graph), so the
        // uint256 subtraction is safe and the equality compares the two
        // settled-net balances directly.
        return sumLockedEth - sumReleasedEth == sumMintedVerus - sumBurnedVerus;
    }
}
