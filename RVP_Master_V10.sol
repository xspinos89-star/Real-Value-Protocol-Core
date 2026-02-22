// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RVPMasterV10Final is ERC20, Ownable {
    
    uint256 public totalInfraAir;           
    uint256 public physicalInfrastructure; 
    uint256 public digitalInfrastructure;  
    
    mapping(address => uint256) public userLiquidity;    
    mapping(address => uint256) public depositTimestamp; 

    constructor() ERC20("Real Value Token", "RVT") Ownable(msg.sender) {}

    function deposit() public payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        
        userLiquidity[msg.sender] += msg.value;
        depositTimestamp[msg.sender] = block.timestamp;

        uint256 airAmount = (msg.value * 90) / 100;
        _mint(msg.sender, airAmount);
        totalInfraAir += airAmount;
    }

    function buildPhysicalInfra(uint256 _amount) public onlyOwner {
        require(totalInfraAir >= _amount, "Insufficient generated air");
        totalInfraAir -= _amount;
        physicalInfrastructure += _amount;
    }

    function buildDigitalInfra(uint256 _amount) public onlyOwner {
        require(totalInfraAir >= _amount, "Insufficient generated air");
        totalInfraAir -= _amount;
        digitalInfrastructure += _amount;
    }

    function withdraw(uint256 _amount) public {
        require(userLiquidity[msg.sender] >= _amount, "Insufficient liquidity balance");
        
        uint256 airToBurn = (_amount * 90) / 100;
        _burn(msg.sender, airToBurn);
        
        userLiquidity[msg.sender] -= _amount;
        if(userLiquidity[msg.sender] == 0) depositTimestamp[msg.sender] = 0;
        
        // Modern secure transfer method (No warnings)
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function getVotingPower(address _user) public view returns (uint256) {
        if (userLiquidity[_user] == 0) return 0;
        uint256 duration = block.timestamp - depositTimestamp[_user];
        return balanceOf(_user) * duration;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) {
            revert("RVP tokens are Soulbound and non-transferable");
        }
        super._update(from, to, value);
    }
}
