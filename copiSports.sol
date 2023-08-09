// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OddsCalculator is ReentrancyGuard, Ownable { 
    uint256 public odds1;
    uint256 public odds2;
    uint256 public odds0;

    struct Bet {
        address bettor;
        uint256 choice;
        uint256 amount;
    }

    uint public totalBets1;
    uint public totalBets2;
    uint public totalBets0;

    uint256 public bettedAmount1 = totalBets1 * odds1;
    uint256 public bettedAmount2 = totalBets2 * odds2;
    uint256 public bettedAmount0 = totalBets0 * odds0;

    address public USDCTokenAddress;
    bool public isBettingOpen = true;
    uint256 public winnerTeam;
    bool public hasResult = false;

    mapping(address => Bet[]) public userBets;
    Bet[] public allBets; // Array to store all bets

    mapping(address => uint) public personalPlacedBets1;
    mapping(address => uint) public personalPlacedBets2;
    mapping(address => uint) public personalPlacedBets0;

    constructor(uint256 _odds1, uint256 _odds2, uint256 _odds0, address _USDCTokenAddress) {
        odds1 = _odds1;
        odds2 = _odds2;
        odds0 = _odds0;
        USDCTokenAddress = _USDCTokenAddress;
    }

    function placeBet(uint256 _amount, uint256 _choice) public payable nonReentrant {
        require(isBettingOpen, "Betting is closed");
        require(
            IERC20(USDCTokenAddress).balanceOf(msg.sender) >= _amount,
            "Not enough tokens"
        );

        Bet memory newBet = Bet({
            bettor: msg.sender,
            choice: _choice,
            amount: _amount
        });
        allBets.push(newBet); // Store the bet in the allBets array

        if (_choice == 1) {
            personalPlacedBets1[msg.sender] += _amount;
            totalBets1 += _amount;
        } else if (_choice == 2) {
            personalPlacedBets2[msg.sender] += _amount;
            totalBets2 += _amount;

        } else if (_choice == 0) {
            personalPlacedBets0[msg.sender] += _amount;
            totalBets0 += _amount;

        } else {
            revert("Invalid bet");
        }
        IERC20(USDCTokenAddress).transferFrom(address(msg.sender), address(this), _amount);
    }


    function getChoiceSums() public view returns (uint256 smallestChoice,uint256 lastBetIndex, uint256 product1, uint256 product2, uint256 product0) {
        uint256 sumChoice1;
        uint256 sumChoice2;
        uint256 sumChoice0;
        
        for (uint256 i = 0; i < allBets.length; i++) {
            if (allBets[i].choice == 1) {
                sumChoice1 += allBets[i].amount;
            } else if (allBets[i].choice == 2) {
                sumChoice2 += allBets[i].amount;
            } else if (allBets[i].choice == 0) {
                sumChoice0 += allBets[i].amount;
            }
        }
        
        product1 = sumChoice1 * odds1;
        product2 = sumChoice2 * odds2;
        product0 = sumChoice0 * odds0;

        smallestChoice = product1; // Assume choice 1 is the smallest
        uint256 smallestChoiceIndex = 1; // Index of choice 1

        if (product2 < smallestChoice) {
            smallestChoice = product2;
            smallestChoiceIndex = 2;
        }
        
        if (product0 < smallestChoice) {
            smallestChoice = product0;
            smallestChoiceIndex = 0;
        }
        
        // Find the last bet index for the smallest choice
        for (uint256 i = allBets.length - 1; i >= 0; i--) {
            if (allBets[i].choice == smallestChoiceIndex) {
                lastBetIndex = i;
                break;
            }
        }
    }



    /*function finalizeBetsAndRefund() public onlyOwner {
        isBettingOpen = false;
        getChoiceSums();

        if (bettedAmount1 <= bettedAmount2 && bettedAmount1 <= bettedAmount0) {
            uint returnsTo2 = bettedAmount2 - bettedAmount1;
            uint returnsTo0 = bettedAmount0 - bettedAmount1;

            
        } else if (bettedAmount2 <= bettedAmount1 && bettedAmount2 <= bettedAmount0) {
            uint returnsTo1 = bettedAmount1 - bettedAmount2;
            uint returnsTo0 = bettedAmount0 - bettedAmount2;


        } else {
            uint returnsTo1 = bettedAmount1 - bettedAmount0;
            uint returnsTo2 = bettedAmount2 - bettedAmount0;
            } 
    }*/
    function getBetCount(address _user) public view returns (uint256) {
        return userBets[_user].length;
    }

    function getBetDetails(address _user, uint256 _index) public view returns (uint256 choice, uint256 amount) {
        Bet storage bet = userBets[_user][_index];
        return (bet.choice, bet.amount);
    }

    // Get all bets
    function getAllBetsCount() public view returns (uint256) {
        return allBets.length;
    }

    function getAllBetDetails(uint256 _index) public view returns (uint256 choice, uint256 amount) {
        Bet storage bet = allBets[_index];
        return (bet.choice, bet.amount);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}
