// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AaveLottery {
    struct Round {
        uint256 endTime; // End time of round
        uint256 totalStake; // Total amount of ETH staked from, all users
        uint256 award; // Jackpot amount
        uint256 winnerTicket; // Index of winner
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
        _updateState();
        // User enters
        // Transfer funds in
        // Deposit user funds into Aave Pool

        require(msg.value >= 0.01 ether, "Not enough ETH");
    }

    // User to exit lottery
    function exit(uint256 roundId) external {
        // Validation
        // Updates
        _updateState();
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

    // Randomly select a winner
    // total is the sum of stakes in a round
    // for simplicity we map each user stakes to a range of an array like representation
    // user1 stakes 100 ETH, user2 stakes 200 ETH, user3 stakes 300 ETH
    // [0..99] => user1
    // [100..299] => user2
    // [300..599] => user3
    // total = 600
    function _drawWinner(
        uint256 total
    ) internal view returns (uint) {
        // !Important: Do not use in production.
        // TODO: Use Chainlink VRF to generate random number
        // https://docs.chain.link/docs/get-a-random-number/

        // [0..2^256-1)
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    rounds[currentId].totalStake,
                    currentId
                )
            )
        );

        // TODO: deal with modulo bias
        return randomNumber % total;
    }

    function _updateState() internal {
        // Check if round is over
        if (block.timestamp > rounds[currentId].endTime) {
            // Draw winner
            rounds[currentId].winnerTicket = _drawWinner(rounds[currentId].totalStake);
     
            // Create new round
            rounds[++currentId].endTime = block.timestamp + roundDuration;
        }
    }
}
