// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {IAToken} from "aave-v3-core/contracts/interfaces/IAToken.sol";
import {DataTypes} from "aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";
import {WadRayMath} from "aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol";

contract AaveLottery {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    struct Round {
        uint256 endTime; // End time of round
        uint256 totalStake; // Total amount of ETH staked from, all users
        uint256 award; // Jackpot amount
        uint256 winnerTicket; // Index of winner
        address winner; // Winner of round
    }

    struct Ticket {
        uint256 stake; // Amount of ETH staked
        uint256 segmentStart; // Start of segment in array [totalStake... totalStake + stake]
        bool exited; // Whether user has exited, i.e. withdrawn funds
    }

    // Duration of each round in seconds
    uint256 public roundDuration;

    // Current round id
    uint256 public currentId;

    // Underlying asset
    IERC20 public underlying;

    // Aave Pool
    IPool private aave;

    // Aave aToken
    IAToken private aToken;

    // Mapping of roundId to Round
    mapping(uint256 => Round) public rounds;

    // Mapping of Round to User to Ticket
    // roundId => userAddress => Ticket
    mapping(uint256 => mapping(address => Ticket)) public tickets;

    // C-tor
    constructor(
        uint256 _roundDuration,
        address _underlying,
        address _aavePool
    ) {
        roundDuration = _roundDuration;
        underlying = IERC20(_underlying);
        aave = IPool(_aavePool);

        // get aToken for the underlying asset
        DataTypes.ReserveData memory data = aave.getReserveData(_underlying);
        require(data.aTokenAddress != address(0), "ATOKEN_NOT_FOUND");
        aToken = IAToken(data.aTokenAddress);

        // allow aave to spend underlying
        require( underlying.approve(_aavePool, type(uint256).max), "APPROVE_FAILED");

        // Create first round
        rounds[currentId] = Round(
            block.timestamp + roundDuration,
            0,
            0,
            0,
            address(0)
        );
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
    function enter(uint256 amount) external {
        // Validation
        require(tickets[currentId][msg.sender].stake == 0, "ALREADY_ENTERED");

        // Updates
        _updateState();

        // User enters
        // Tiket memory ticket = Ticket(amount, rounds[currentId].totalStake, false);
        tickets[currentId][msg.sender].stake = amount;
        tickets[currentId][msg.sender].segmentStart = rounds[currentId]
            .totalStake;
        rounds[currentId].totalStake += amount;

        // Transfer funds in
        underlying.safeTransferFrom(msg.sender, address(this), amount); // user ,ust approve this contract to spend their funds

        // Deposit user funds into Aave Pool
    }

    // User to exit lottery
    function exit(uint256 roundId) external {
        // Validation
        require(!tickets[roundId][msg.sender].exited, "ALREADY_EXITED");

        // Updates
        _updateState();
        require(roundId < currentId, "ROUND_NOT_OVER");

        // User exits
        uint256 amount = tickets[roundId][msg.sender].stake;
        tickets[roundId][msg.sender].exited = true;
        rounds[roundId].totalStake -= amount;

        // Transfer funds out
        underlying.safeTransfer(msg.sender, amount);

        // Deposit user funds into Aave Pool
        payable(msg.sender).transfer(address(this).balance);
    }

    // User to claim lottery
    function claim(uint256 roundId) external {
        // Validation
        require(roundId < currentId, "ROUND_NOT_OVER");

        // Check winner
        Ticket memory ticket = tickets[roundId][msg.sender];
        Round memory round = rounds[roundId];

        // round.winnerTicket belongs to [tiket.segmentStart... ticket.segmentStart + ticket.stake)
        require(
            round.winnerTicket - ticket.segmentStart < ticket.stake,
            "NOT_WINNER"
        );

        require(round.winner == address(0), "ALREADY_CLAIMED");
        round.winner = msg.sender;

        // Transfer jackpot to winner
        underlying.safeTransfer(msg.sender, round.award);
    }

    // Randomly select a winner
    // total is the sum of stakes in a round
    // for simplicity we map each user stakes to a range of an array like representation
    // user1 stakes 100 ETH, user2 stakes 200 ETH, user3 stakes 300 ETH
    // [0..99] => user1
    // [100..299] => user2
    // [300..599] => user3
    // total = 600
    function _drawWinner(uint256 total) internal view returns (uint) {
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
            rounds[currentId].winnerTicket = _drawWinner(
                rounds[currentId].totalStake
            );

            // Create new round
            rounds[++currentId].endTime = block.timestamp + roundDuration;
        }
    }
}
