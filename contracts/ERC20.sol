// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract ROK_Token is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**18;
    uint256 public constant WHITE_LIST_PRICE = 1 ether / 10;
    uint256 public constant NORMAL_PRICE = 1 ether;

    //토큰 컨트랙트랑, 스테이킹 컨트랙트 -> 토큰 컨트랙트에서 토큰 구입이 가능하며, 나중에 인출이 가능하다. 스테이킹 컨트랙트에서는 스테이킹만!
    address public stakingContract;

    //세일 컨트랙트 true, false 토큰 판매 할껀지 말껀지
    bool public saleActive;
    mapping(address => bool) public whitelist;
    
    constructor() ERC20("ROK_Token", "ROK") {

    }

    //mint는 우리가 스테이킹 컨트랙트마 접근이 가능하게 만드는 역할
    function mint(address to, uint256 amount) external {
        require(msg.sender == stakingContract, "Only staking contract can mint tokens");
        _mint(to, amount);
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }

    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
    }

    function addToWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }

    function removeFromWhitelist(address user) external onlyOwner {
        whitelist[user] = false;
    }

    function buyTokens() external payable nonReentrant {
        //require(saleActive, "Sale is not active");
        uint256 tokenAmount = getTokenAmount(msg.value);
        require(tokenAmount > 0, "Invalid token amount");
        _mint(msg.sender, tokenAmount); 
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    function transferToContractAndClaimEther(uint256 amount) external {
        require(amount >= 100 * 10**18, "You need to transfer at least 100 tokens");
        super.transfer(address(this), amount);
        //내가 넣은 가격의 / 100 * 10 < 가장 적절한 비율 계산법
        uint256 etherToTransfer = address(this).balance.mul(amount / (10 ** 4)).div(10 * (10 ** 18));
        require(etherToTransfer > 0, "No ether available to claim");
        
        (bool success, ) = msg.sender.call{value: etherToTransfer}("");
        require(success, "Transfer failed.");
    }

    function getTokenAmount(uint256 ethAmount) public view returns (uint256) {
        uint256 price = whitelist[msg.sender] ? WHITE_LIST_PRICE : NORMAL_PRICE;
        return (ethAmount * 10000 * (10 ** 18)).div(price);
    }

    function receiveEther() external payable {}

}
