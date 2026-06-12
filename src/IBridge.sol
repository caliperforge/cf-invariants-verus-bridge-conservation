// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

/// @notice IBridge — shared surface MinimalBridge and PlantedBridge both expose.
///
/// The Chimera harness (`test/recon/`) binds against this interface so the
/// same TargetFunctions, Properties, and BeforeAfter files drive either
/// implementation. Two CryticTester variants pick which concrete contract
/// to deploy — CryticCleanTester → MinimalBridge, CryticPlantedTester →
/// PlantedBridge — and the CI matrix runs both.
interface IBridge {
    function bridgeIn(uint256 amount) external;
    function bridgeOut(uint256 amount) external;

    function sumLockedEth() external view returns (uint256);
    function sumReleasedEth() external view returns (uint256);
    function sumMintedVerus() external view returns (uint256);
    function sumBurnedVerus() external view returns (uint256);

    function wrappedVerusBalance(address user) external view returns (uint256);

    function conservationHolds() external view returns (bool);
}
