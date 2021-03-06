// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "./AdventureIslandInternal/AdventureIslandInternal.sol";

contract AdventureIslandViews is AdventureIslandInternal {
    function poolsCount() external view returns(uint256) {
        return validPoolList.length;
    }

    function poolsEnabled() external view returns(bool) {
        return _poolsEnabled();
    }

    function getToBeCollectListOf(address user) public view
        returns(uint256[] memory userReward,
                uint256[] memory poolReward,
                uint256[] memory userStaked,
                uint256[] memory poolStaked) {
        uint256[] memory userReward = new uint256[](allPoolsCount);
        uint256[] memory poolReward = new uint256[](allPoolsCount);
        uint256[] memory userStaked = new uint256[](allPoolsCount);
        uint256[] memory poolStaked = new uint256[](allPoolsCount);

        for(uint256 i=0; i<allPoolsCount; i++) {
            (userReward[i], poolReward[i], userStaked[i], poolStaked[i]) = toBeCollectedOf(i, user);
        }
        return (userReward, poolReward, userStaked, poolStaked);
    }

    function poolWeight(uint256 _pid) external view returns(uint256) {
        PoolInfo storage pool = allPools[_pid];
        if(pool.closed) {
            return 0;
        }

        return pool.weight.mul(COMMON_PRECISION).div(_poolsTotalWeight());
    }

    function toBeCollectedOfPool(uint256 _pid) public view returns(uint256){
        PoolInfo storage pool = allPools[_pid];
        if(pool.billingCycle == 0) {
            return 0;
        }

        if(pool.staked == 0) {
            return 0;
        }

        return _toBeCollected(pool, pool.lastRewardBlock, block.number);
    }

    function toBeCollectedOf(uint256 _pid, address _user) public view returns(uint256, uint256, uint256, uint256) {
        PoolInfo storage pool = allPools[_pid];
        UserInfo storage user = users[_pid][_user];

        if(pool.staked == 0) {
            return (0, 0, 0, 0);
        }

        if(pool.billingCycle == 0) {
            return (0, 0, 0, 0);
        }

        if(block.number < pool.startBlock) {
            return (0, 0, 0, 0);
        }

        uint256 poolToBeCollect = toBeCollectedOfPool(_pid);
        uint256 rewardPerShare = pool.rewardPerShare.add(poolToBeCollect.mul(COMMON_PRECISION).div(pool.staked));

        if(user.stakeIn == 0) {
            return (0, poolToBeCollect, 0, pool.staked);
        }


        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(rewardPerShare).div(COMMON_PRECISION).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);

        return (userReward, poolToBeCollect, user.stakeIn, pool.staked);
    }

    function getPoolStakingToken(uint256 _pid) external view returns(address) {
        return address(allPools[_pid].stakingToken);
    }

    function getStakedInfoOf(address userAddr) external view returns(address[] memory, uint256[] memory, uint256[] memory, uint256[] memory,  uint256[] memory,  uint256[] memory) {
        address[] memory stakeTokenList = new address[](allPoolsCount);
        uint256[] memory stakeTokenTotalSupply = new uint256[](allPoolsCount);

        uint256[] memory userStaked = new uint256[](allPoolsCount);
        uint256[] memory userReward = new uint256[](allPoolsCount);
        uint256[] memory poolStaked = new uint256[](allPoolsCount);
        uint256[] memory poolReward = new uint256[](allPoolsCount);

        (userReward, poolReward, userStaked, poolStaked) = getToBeCollectListOf(userAddr);

        for(uint256 i=0; i<allPoolsCount; i++) {
            PoolInfo memory p = allPools[i];

            stakeTokenList[i] = address (p.stakingToken);
            stakeTokenTotalSupply[i] = p.stakingToken.totalSupply();
        }

        return (stakeTokenList, stakeTokenTotalSupply, userReward, poolReward, userStaked, poolStaked);
    }
}
