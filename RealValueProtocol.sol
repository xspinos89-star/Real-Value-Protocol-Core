// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RealValueToken.sol";

/**
 * @title RealValueProtocol
 * @author Christos Spinos
 * @notice The core engine for 90/10 split between Physical Infrastructure and AI Tools.
 * @dev This contract implements the "Recycler Engine" logic described in the White Paper.
 */
contract RealValueProtocol is Ownable {
    
    RealValueToken public rvtToken;
    
    // Core Pillars: Physical RWA and Digital AI Development
    address public infrastructureFund; // 90% allocation
    address public treasuryBank;      // 10% allocation

    // Economic Metrics
    uint256 public totalValueRecycled;
    uint256 public impactMultiplier = 10;

    event ValueRecycled(address indexed user, uint256 totalAmount, uint256 infraAmount, uint256 treasuryAmount);
    event ImpactScoreMinted(address indexed user, uint256 score);

    /**
     * @param _rvtToken The address of the deployed RVT token
     * @param _infraFund The address for the Infrastructure & AI pool
     * @param _treasuryBank The address for protocol sustainability
     */
    constructor(address _rvtToken, address _infraFund, address _treasuryBank) Ownable(msg.sender) {
        rvtToken = RealValueToken(_rvtToken);
        infrastructureFund = _infraFund;
        treasuryBank = _treasuryBank;
    }

    /**
     * @notice Processes incoming value and executes the 90/10 split.
     * @dev Implements V_impact = F * 0.90 | V_treasury = F * 0.10
     */
    function recycleValue() external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        uint256 amount = msg.value;
        
        // 1. Execute Mathematical Logic Split
        uint256 infraAmount = (amount * 90) / 100;
        uint256 treasuryAmount = amount - infraAmount;

        // 2. Fund Physical & Digital Assets
        (bool success1, ) = payable(infrastructureFund).call{value: infraAmount}("");
        (bool success2, ) = payable(treasuryBank).call{value: treasuryAmount}("");
        
        require(success1 && success2, "On-chain transfer to funds failed");

        // 3. Update Macroeconomic Metrics
        totalValueRecycled += amount;

        // 4. Reward User with Social Impact Score (SIS) through RVT
        // Formula: SIS = V_impact * Impact Constant (10)
        uint256 impactScore = infraAmount * impactMultiplier;
        rvtToken.mint(msg.sender, impactScore);

        emit ValueRecycled(msg.sender, amount, infraAmount, treasuryAmount);
        emit ImpactScoreMinted(msg.sender, impactScore);
    }

    /**
     * @notice Adjust the impact multiplier based on protocol growth.
     */
    function setImpactMultiplier(uint256 _newMultiplier) external onlyOwner {
        impactMultiplier = _newMultiplier;
    }

    /**
     * @notice Update project funding addresses.
     */
    function updateAssetAddresses(address _newInfra, address _newTreasury) external onlyOwner {
        infrastructureFund = _newInfra;
        treasuryBank = _newTreasury;
    }

    /**
     * @dev Fallback to allow direct ETH transfers to trigger the Recycler.
     */
    receive() external payable {
        if (msg.value > 0) {
            this.recycleValue();
        }
    }
}
