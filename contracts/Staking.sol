pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    address public owner;

    uint public currentTokenId = 1;
    uint public constant INTEREST_RATE = 2; 

    struct TokenInfo {
        uint tokenId;
        string tokenName;
        string tokenSymbol;
        address tokenContractAddress;
        uint usdPrice;
        uint ethPrice;
        uint annualPercentageYield;
    }

    struct Stake {
        uint stakeId;
        address walletAddress;
        string tokenName;
        string tokenSymbol;
        uint createdDate;
        uint annualPercentageYield;
        uint tokenQuantity;
        uint usdValue;
        uint ethValue;
        bool isOpen;
    }

    uint public ethUsdPrice;
    uint public lastInterestBlock;

    string[] public tokenSymbols;
    mapping(string => TokenInfo) public tokens;

    uint public currentStakeId = 1;
    mapping(uint => Stake) public stakes;
    mapping(address => uint[]) public stakeIdsByAddress;
    mapping(string => uint) public stakedTokenQuantities;

    constructor(uint currentEthPrice) payable {
        ethUsdPrice = currentEthPrice;
        owner = msg.sender;
        lastInterestBlock = block.number;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Only the owner can call this function");
        _;
    }

    function addToken(
        string calldata name,
        string calldata symbol,
        address tokenAddress,
        uint usdPrice,
        uint annualPercentageYield
    ) external onlyOwner {
        tokenSymbols.push(symbol);
        tokens[symbol] = TokenInfo(
            currentTokenId,
            name,
            symbol,
            tokenAddress,
            usdPrice,
            usdPrice / ethUsdPrice,
            annualPercentageYield
        );

        currentTokenId += 1;
    }

    function getTokenSymbols() public view returns (string[] memory) {
        return tokenSymbols;
    }

    function getTokenInfo(string calldata tokenSymbol) public view returns (TokenInfo memory) {
        return tokens[tokenSymbol];
    }

    function stakeTokens(string calldata symbol, uint tokenQuantity) external {
        require(tokens[symbol].tokenId != 0, "This token cannot be staked");

        IERC20(tokens[symbol].tokenContractAddress).transferFrom(msg.sender, address(this), tokenQuantity);
        stakes[currentStakeId] = Stake(
            currentStakeId,
            msg.sender,
            tokens[symbol].tokenName,
            symbol,
            block.timestamp,
            tokens[symbol].annualPercentageYield,
            tokenQuantity,
            tokens[symbol].usdPrice * tokenQuantity,
            (tokens[symbol].usdPrice * tokenQuantity) / ethUsdPrice,
            true
        );

        stakeIdsByAddress[msg.sender].push(currentStakeId);
        currentStakeId += 1;
        stakedTokenQuantities[symbol] += tokenQuantity;
    }

    function getStakeIdsForAddress() external view returns (uint[] memory) {
        return stakeIdsByAddress[msg.sender];
    }

    function getStakeById(uint stakeId) external view returns (Stake memory) {
        return stakes[stakeId];
    }

    function calculateCompoundInterest(uint value, uint rate, uint periods) public pure returns (uint) {
        uint compoundInterest = value;
        for (uint i = 0; i < periods; i++) {
            compoundInterest = (compoundInterest * (10000 + rate)) / 10000;
        }
        return compoundInterest - value;
    }

    function updateStakesWithInterest() external {
        require(block.number >= lastInterestBlock + 10, "Cannot update stakes yet");

        uint numberOfBlocks = block.number - lastInterestBlock;
        for (uint i = 0; i < currentStakeId; i++) {
            Stake storage stake = stakes[i];
            if (stake.isOpen) {
                uint interestAmount = calculateCompoundInterest(stake.ethValue, INTEREST_RATE, numberOfBlocks);
                stake.ethValue += interestAmount;
                stake.usdValue = stake.ethValue * ethUsdPrice;
            }
        }

        lastInterestBlock = block.number;
    }

    function closeStake(uint stakeId) external {
        require(stakes[stakeId].walletAddress == msg.sender, "Not the owner of this stake");
        require(stakes[stakeId].isOpen == true, "Stake already closed");
        stakes[stakeId].isOpen = false;
        IERC20(tokens[stakes[stakeId].tokenSymbol].tokenContractAddress).transfer(
            msg.sender,
            stakes[stakeId].tokenQuantity
        );
        uint interestAmount = calculateCompoundInterest(
            stakes[stakeId].ethValue,
            INTEREST_RATE,
            block.number - stakes[stakeId].createdDate
        );

        payable(msg.sender).call{ value: interestAmount }("");
    }

    function modifyStakeCreatedDate(uint stakeId, uint newCreatedDate) external onlyOwner {
        stakes[stakeId].createdDate = newCreatedDate;
    }
}
