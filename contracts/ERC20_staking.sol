// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol"; 

contract ROK_Staking is ReentrancyGuard{
    using SafeMath for uint256;

    uint256 public constant STAKING_REWARD_PERCENT = 1;
    uint256 public constant REWARD_PERIOD = 10;
    uint256 public constant PERIOD_14_DAYS = 14 days;
    uint256 public constant PERIOD_30_DAYS = 30 days;
    uint256 public constant PERIOD_90_DAYS = 90 days;

    mapping(address => StakeInfo) public stakeInfos;

    ROK_Token public rokToken;

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    constructor(address tokenAddress) {
        rokToken = ROK_Token(tokenAddress);
    }

    function stake(uint256 amount) external nonReentrant {
        require(rokToken.balanceOf(msg.sender) >= (100 * 10 ** 18), "100 * 18 ** 18 balance for staking");
        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        require(stakeInfo.amount == 0, "Already staked. Unstake first.");
        stakeInfo.amount = stakeInfo.amount.add(amount);
        stakeInfo.timestamp = block.timestamp;
        rokToken.transferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        require(stakeInfo.amount >= (100 * 10 ** 18), "Trying to unstake more than you have");
        uint256 reward = calculateReward(msg.sender);
        rokToken.mint(msg.sender, reward);
        rokToken.transfer(msg.sender, amount);
        stakeInfo.amount = stakeInfo.amount.sub(amount);
        stakeInfo.timestamp = block.timestamp;
    }

    //stakeInfo에 대해서 add를 할때 sub을 할때 add + sub = 0
    function unstakeAll() external nonReentrant {
        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        require(stakeInfo.amount >= 0, "You have no staked tokens");
        uint256 reward = calculateReward(msg.sender);
        rokToken.mint(msg.sender, reward);
        rokToken.transfer(msg.sender, stakeInfo.amount);
        stakeInfo.amount = 0;
        stakeInfo.timestamp = 0;
    }

    function claimReward() external nonReentrant {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards available");
        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        stakeInfo.timestamp = block.timestamp;
        rokToken.mint(msg.sender, reward);
    }

    function reStake() external payable nonReentrant {
        require(msg.value == 1 ether, "You must send exactly 1 ether");
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards available");
        StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        rokToken.mint(msg.sender, reward);
        rokToken.transferFrom(msg.sender, address(this), reward);
        stakeInfo.amount = stakeInfo.amount.add(reward);
        stakeInfo.timestamp = block.timestamp;

        // 이더리움을 ERC20.sol 컨트랙트로 전송합니다.
        rokToken.receiveEther{value: msg.value}();
    }

    function calculateReward(address staker) public view returns (uint256) {
        StakeInfo memory stakeInfo = stakeInfos[staker];
        uint256 timeDiff = block.timestamp.sub(stakeInfo.timestamp);
        uint256 reward = stakeInfo.amount.mul(STAKING_REWARD_PERCENT).mul(timeDiff).div(REWARD_PERIOD).div(100);
        if (timeDiff >= PERIOD_90_DAYS) {
            reward = reward.mul(18).div(10); // 1.8x for 90+ days
        } else if (timeDiff >= PERIOD_30_DAYS) {
            reward = reward.mul(12).div(10); // 1.2x for 30+ days
        } else if (timeDiff >= PERIOD_14_DAYS) {
            reward = reward.mul(8).div(10); // 0.8x for 14+ days
        }
        return reward;
    }

    function getTime() public view returns (uint256) {
        uint256 getTimeStamp = block.timestamp;
        return getTimeStamp;
    }
}