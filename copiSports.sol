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
    
    mapping(address => uint256) public contributionPercentages;


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


    function getSmallestChoiceAndLastBetIndex() public view returns (uint256 smallestChoice,uint256 lastBetIndex, uint256 product1, uint256 product2, uint256 product0) {
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



    function finalizeBetsAndRefund() public onlyOwner {
        require(!hasResult, "Bets are already finalized");
        isBettingOpen = false;
        uint256 lastBetIndex;
        (, lastBetIndex, , ,) = getSmallestChoiceAndLastBetIndex();

        // Refund tokens for bets made after lastBetIndex
        for (uint256 i = lastBetIndex + 1; i < allBets.length; i++) {
            Bet memory bet = allBets[i];
            uint256 refundAmount = bet.amount;
            IERC20(USDCTokenAddress).transferFrom(address(this),bet.bettor, refundAmount);
        }
    }

    function winner(uint256 _choice) public onlyOwner {
        require(!isBettingOpen, "Open bets");
        require(_choice == 0 || _choice == 1 || _choice == 2, "Invalid choice");

        hasResult = true;

        uint256 smallestChoice;
        uint256 lastBetIndex;
        (smallestChoice, lastBetIndex, , ,) = getSmallestChoiceAndLastBetIndex();

        
        // Calculate the total contribution to the smallestChoice
        uint256 totalContributedAmount = 0;
        
        for (uint256 i = 0; i <= lastBetIndex; i++) {
            if (allBets[i].choice == _choice) {
                totalContributedAmount += allBets[i].amount;
            }
        }
        emit TotalContributedAmount(totalContributedAmount);
        // Calculate and store the contribution percentage for each address
        
        for (uint256 i = 0; i <= lastBetIndex; i++) {
            if (allBets[i].choice == _choice) {
                uint256 contributionPercentage = (allBets[i].amount * 100) / totalContributedAmount;
                contributionPercentages[allBets[i].bettor] = contributionPercentage;
                emit ContributionPercentage(allBets[i].bettor, contributionPercentage);
            }
        }
        
        // Calculate the total tokens in the contract
        uint256 totalTokensInContract = IERC20(USDCTokenAddress).balanceOf(address(this));
        
        // Distribute tokens to winners according to their contribution percentages
        for (uint256 i = 0; i <= lastBetIndex; i++) {
            if (allBets[i].choice == _choice) {
                uint256 tokensToTransfer = (totalTokensInContract * contributionPercentages[allBets[i].bettor]) / 100;
                emit TokensTransferred(allBets[i].bettor, tokensToTransfer);
                IERC20(USDCTokenAddress).transferFrom(address(this),allBets[i].bettor, tokensToTransfer);
            }
        }
    }
    event TotalContributedAmount(uint256 totalAmount);
    event ContributionPercentage(address indexed bettor, uint256 percentage);
    event TokensTransferred(address indexed bettor, uint256 tokens);

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
