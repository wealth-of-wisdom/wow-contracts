// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Nft} from "../../contracts/Nft.sol";

contract NftMock is Nft {
    function mock_setNftAmount(uint16 level, bool isGenesis, uint256 amount) external {
        s_nftLevels[_getLevelHash(level, isGenesis)].nftAmount = amount;
    }
}
