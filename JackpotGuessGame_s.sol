// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract JackpotGuessGame {
    address public owner;
    bytes32 private secretHash; // hash of the correct number
    uint256 public entryFee = 0.01 ether;
    uint256 public pot;
    bool public gameActive;
    uint256 public guesses;

    event GameStarted(bytes32 hash);
    event WrongGuess(address indexed player, uint256 guess);
    event JackpotWon(address indexed winner, uint256 guess, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Start a new game with the hash of a secret number (e.g. keccak256(abi.encodePacked(42)))
    function startGame(bytes32 _secretHash) external onlyOwner {
        require(!gameActive, "Game already active");

        secretHash = _secretHash;
        pot = 0;
        guesses = 0;
        gameActive = true;

        emit GameStarted(secretHash);
    }

    /// @notice Players guess the number (off-chain hashed)
    function guessNumber(uint256 guess) external payable {
        require(gameActive, "Game not active");
        require(msg.value == entryFee, "Send exact entry fee");

        guesses += 1;

        if (keccak256(abi.encodePacked(guess)) == secretHash) {
            // Correct guess
            uint256 reward = pot + msg.value;
            gameActive = false;
            pot = 0;
            payable(msg.sender).transfer(reward);

            emit JackpotWon(msg.sender, guess, reward);
        } else {
            // Wrong guess
            pot += msg.value;
            emit WrongGuess(msg.sender, guess);
        }
    }

    /// @notice Emergency stop if needed
    function endGame() external onlyOwner {
        gameActive = false;
    }

    /// @notice Withdraw funds if game ends without winner
    function emergencyWithdraw() external onlyOwner {
        require(!gameActive, "Game still active");
        payable(owner).transfer(address(this).balance);
    }

    /// View pot amount
    function getPot() external view returns (uint256) {
        return pot;
    }
}
