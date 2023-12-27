// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AaveLottery {
    struct Round {
        uint256 endTime; // End time of round
        uint256 totalStake; // Total amount of ETH staked from, all users
        uint256 award; // Jackpot amount
        address winner; // Winner of round
    }

    struct Ticket {
        uint256 stake; // Amount of ETH staked
    }

    // Duration of each round in seconds
    uint256 public roundDuration;

    // Current round id
    uint256 public currentId;

    // Mapping of roundId to Round
    mapping(uint256 => Round) public rounds;

    // Mapping of Round to User to Ticket
    // roundId => userAddress => Ticket
    mapping(uint256 => mapping(address => Ticket)) public tickets;

    // C-tor
    constructor(uint256 _roundDuration) {
        roundDuration = _roundDuration;
    }

    function getRound(uint256 roundId) external view returns (Round memory) {
        // Validation
        // Return round
        return rounds[roundId];
    }

    function getTicket(
        uint256 roundId,
        address user
    ) external view returns (Ticket memory) {
        // Validation
        // Return ticket
        return tickets[roundId][user];
    }

    // User to enter lottery
    function enter(uint256 amount) external payable {
        // Validation
        // Updates
        // User enters
        // Transfer funds in
        // Deposit user funds into Aave Pool

        require(msg.value >= 0.01 ether, "Not enough ETH");
    }

    // User to exit lottery
    function exit(uint256 roundId) external {
        // Validation
        // Updates
        // User exits
        // Transfer funds out
        // Deposit user funds into Aave Pool
        payable(msg.sender).transfer(address(this).balance);
    }

    // User to claim lottery
    function claim(uint256 roundId) external {
        // Validation
        // Check winner
        // Transfer jackpot to winner

        payable(msg.sender).transfer(address(this).balance);
    }

    // Random number generator
    // Do not use in production.  TODO: Use Chainlink VRF to generate random number
    // https://docs.chain.link/docs/get-a-random-number/
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        rounds[currentId].totalStake,
                        currentId
                    )
                )
            );
    }
}
