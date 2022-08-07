// Raffle


// Enter the lottery and pay some amount
// pick a random winner (verifiabley random)
// Winner to be selected every X minutes -> completely automated

// chainlink Oracle -> randomess, automated execution

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error Lottery__LowerThanEntranceFee();
error Lottery__TransferFailed();

contract Lotter is VRFConsumerBaseV2{
    /* events */
    event LotteryEntered(address indexed participant, uint fee);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed recentWinner);

    /* state variables */
    uint256 private immutable i_entranceFee; // should be 1e18
    address payable [] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    address private s_recentWinner;


    constructor(address vrfCoordinatorV2, uint initial_fee, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = initial_fee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function getEntranceFee() public view returns(uint){
        return i_entranceFee;
    }
    function enterLottery() public payable {
        if (msg.value < i_entranceFee ) {
            revert Lottery__LowerThanEntranceFee();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEntered(msg.sender, msg.value);
    }

    function getPlayer(uint index) public view returns(address) {
        return s_players[index];
    }

    function requestRandomWinner() external {
        // request a random mnumber
        // once we get it, do something with it
        // 2 transactions
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId, // 9963, // s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords)
        internal 
        override 
    {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success,) = recentWinner.call{value: address(this).balance}("");

        // require(seccess)
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }


}
