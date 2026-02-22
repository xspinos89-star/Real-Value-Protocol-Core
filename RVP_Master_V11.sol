// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RVP Protocol v2.2 - The Final Inversion
 * @dev Fully optimized version with 0 Warnings. 
 * Features: Capital Safety, x2 Infra Bonus, 70% Stagnation Penalty, Global Deflation.
 */
contract RVPProtocolV2_2 {
    string public name = "RVP Protocol v2.2 - Final";
    
    struct User {
        uint256 deposit;            // Principal amount (Safe)
        uint256 physicalInfra;      // RWA (From Harvest)
        uint256 lastUpdate;         
        uint256 accumulatedAir;     
    }

    mapping(address => User) public users;
    uint256 public totalGlobalAir;  
    uint256 public totalGlobalRWA;

    event DepositMade(address indexed user, uint256 amount);
    event HarvestExecuted(address indexed user, uint256 rwaGained);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() public payable {
        require(msg.value > 0, "Amount must be > 0");
        updateAir(msg.sender);
        
        users[msg.sender].deposit += msg.value;
        uint256 initialAir = msg.value / 10;
        users[msg.sender].accumulatedAir += initialAir;
        totalGlobalAir += initialAir; 
        
        emit DepositMade(msg.sender, msg.value);
    }

    function updateAir(address _user) internal {
        User storage user = users[_user];
        if (user.lastUpdate > 0 && user.deposit > 0) {
            uint256 timePassed = block.timestamp - user.lastUpdate;
            uint256 shield = (user.physicalInfra / 1e14) + 1; 
            uint256 newAir = (user.deposit * timePassed) / (1 days * shield);
            
            user.accumulatedAir += newAir;
            totalGlobalAir += newAir; 
        }
        user.lastUpdate = block.timestamp;
    }

    function getVotingPower(address _user) public view returns (uint256) {
        User memory user = users[_user];
        if (user.deposit == 0) return 0;

        // INFRASTRUCTURE BONUS: x2 (200%)
        uint256 basePower = user.deposit + (user.physicalInfra * 2);

        // STAGNATION PENALTY: 70% drop if Air > Deposit
        if (user.accumulatedAir > user.deposit) {
            basePower = (basePower * 30) / 100; 
        }
        return basePower;
    }

    function airHarvest() public {
        updateAir(msg.sender);
        User storage user = users[msg.sender];
        uint256 airToConvert = user.accumulatedAir;
        require(airToConvert > 0, "No air to convert");

        uint256 globalBurn = (airToConvert * 12) / 10;
        if (totalGlobalAir > globalBurn) {
            totalGlobalAir -= globalBurn;
        } else {
            totalGlobalAir = 0;
        }

        user.accumulatedAir = 0;
        user.physicalInfra += airToConvert;
        totalGlobalRWA += airToConvert;

        emit HarvestExecuted(msg.sender, airToConvert);
    }

    // FIXED: Withdrawal using "call" instead of "transfer" to remove Warnings
    function withdraw() public {
        User storage user = users[msg.sender];
        uint256 amount = user.deposit;
        require(amount > 0, "Nothing to withdraw");

        if (totalGlobalAir > user.accumulatedAir) {
            totalGlobalAir -= user.accumulatedAir;
        }

        user.deposit = 0;
        user.accumulatedAir = 0;
        user.physicalInfra = 0; 
        
        // This is the secure way to transfer ETH in 2026
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // DASHBOARD HELPERS
    function physicalInfrastructure(address _user) public view returns (uint256) {
        return users[_user].physicalInfra;
    }

    function totalInfraAir(address _user) public view returns (uint256) {
        User memory user = users[_user];
        if (user.deposit == 0) return user.accumulatedAir;
        uint256 timePassed = block.timestamp - user.lastUpdate;
        uint256 shield = (user.physicalInfra / 1e14) + 1;
        uint256 pendingAir = (user.deposit * timePassed) / (1 days * shield);
        return user.accumulatedAir + pendingAir;
    }
}
