// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyDrawVault is Ownable {
    IERC20 public immutable rewardToken;
    address[] public participants;
    mapping(address => uint256) public lastEnteredDay;
    uint256 public rewardAmount = 50 * 10**18;
    uint256 public lastDrawTime;

    event Entered(address indexed user);
    event WinnerPicked(address indexed winner, uint256 amount);

    constructor(address _rewardToken) Ownable(msg.sender) {
        rewardToken = IERC20(_rewardToken);
        lastDrawTime = block.timestamp;
    }

    // User enters once per day
    function enterDraw() external {
        uint256 today = block.timestamp / 1 days;
        require(lastEnteredDay[msg.sender] < today, "Already entered today");

        lastEnteredDay[msg.sender] = today;
        participants.push(msg.sender);

        emit Entered(msg.sender);
    }

    // Pick a winner from current participants
    function drawWinner() external onlyOwner {
        require(participants.length > 0, "No participants");
        require(block.timestamp >= lastDrawTime + 1 days, "Draw allowed once per day");

        // Use pseudo-randomness (testnet safe)
        uint256 winnerIndex = uint256(blockhash(block.number - 1)) % participants.length;
        address winner = participants[winnerIndex];

        rewardToken.transfer(winner, rewardAmount);
        emit WinnerPicked(winner, rewardAmount);

        delete participants;
        lastDrawTime = block.timestamp;
    }

    // Fund the vault
    function fund(uint256 amount) external {
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }

    function setRewardAmount(uint256 amount) external onlyOwner {
        rewardAmount = amount;
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
}
