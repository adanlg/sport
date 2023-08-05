// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Sport {
    uint256 bet1 = 0;
    uint256 bet2 = 0;
    uint256 bet0 = 0;

    address public deltaTokenAddress; // Address of the "delta" token contract

    bool public isBettingOpen = true; // Flag to indicate if betting is still open
    uint256 public closingTime; // Timestamp when betting will be closed

    uint256 public winnerTeam; // Team that wins after betting is closed
    bool public hasResult = false; // Flag to indicate if the result is determined

    mapping(address => uint256) public userBets; // Mapping to store user bets

    constructor(address _deltaTokenAddress, uint256 _closingTime) {
        deltaTokenAddress = _deltaTokenAddress;
        closingTime = _closingTime;
    }

    function placeBet(uint256 _bet, uint256 _team) public payable {
        require(isBettingOpen, "Betting is closed");
        require(block.timestamp < closingTime, "Betting time has passed");
        require(
            IERC20(deltaTokenAddress).balanceOf(msg.sender) >= _bet,
            "Not enough delta tokens"
        );

        if (_team == 1) {
            bet1 += _bet;
        } else if (_team == 2) {
            bet2 += _bet;
        } else if (_team == 0) {
            bet0 += _bet;
        } else {
            revert("Invalid bet");
        }

        // Save the bet for the user
        userBets[msg.sender] += _bet;

        // Transfer the "delta" tokens from the sender to this contract for the bet
        IERC20(deltaTokenAddress).transferFrom(msg.sender, address(this), _bet);
    }

    function closeBetting(uint256 _winnerTeam) public {
        require(isBettingOpen, "Betting is already closed");
        require(block.timestamp >= closingTime, "Betting time has not passed yet");
        require(_winnerTeam == 0 || _winnerTeam == 1 || _winnerTeam == 2, "Invalid team");

        isBettingOpen = false;
        winnerTeam = _winnerTeam;
        hasResult = true;
    }

    function distributeWinnings() public {
        require(!isBettingOpen, "Betting is still open");
        require(hasResult, "Result is not determined yet");

        uint betted1 = bet1 * 167 / 100;
        uint betted2 = bet2 * 419 / 100;
        uint betted0 = bet0 * 603 / 100;

        if (betted1 <= betted2 & betted0) {
            uint total1 = betted1;
            uint total = betted1 * 14142 / 10000;
            
            uint total2 = total * 23834 / 100000;
            uint total0 = total * 1658 / 10000;

            uint cashback2 = bet2 - total2;
            uint cashback0 = bet0 - total0;
        } else if (betted2 <= betted1 & betted0) {
            uint total2 = betted2;
            uint total = betted2 * 176166 / 100000;
            
            uint total1 = total * 59585 / 100000;
            uint total0 = total * 1658 / 10000;

            uint cashback1 = bet1 - total1;
            uint cashback0 = bet0 - total0;
        }  else {
            uint total0 = betted0;
            uint total = betted0 * 18342 / 10000;

            uint total1 = total * 59585 / 100000;
            uint total2 = total * 23834 / 100000;

            uint cashback1 = bet1 - total1;
            uint cashback2 = bet2 - total2;
        }
////hasta aqui de momento.
        uint256 totalBets = bet1 + bet2 + bet0;
        require(totalBets > 0, "No bets placed");

        uint256 totalWinningBets;
        uint256 winnerBetAmount;
        if (winnerTeam == 1) {
            totalWinningBets = bet1;
            winnerBetAmount = totalBets * 167 / 100;
        } else if (winnerTeam == 2) {
            totalWinningBets = bet2;
            winnerBetAmount = totalBets * 419 / 100;
        } else {
            totalWinningBets = bet0;
            winnerBetAmount = totalBets * 603 / 100;
        }

        require(totalWinningBets > 0, "No bets on the winning team");

        for (uint256 i = 0; i < bets.length; i++) {
            address bettor = bets[i].bettor;
            uint256 userBetAmount = userBets[bettor];

            if (bets[i].team == winnerTeam) {
                uint256 winnings = (userBetAmount * winnerBetAmount) / totalWinningBets;
                IERC20(deltaTokenAddress).transfer(bettor, winnings);
            }
        }
    }
}

// Interface for the "delta" token contract
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}
