// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Nft} from "../Nft.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INft is IERC721 {
    function initialize(string memory name, string memory symbol) external;

    function safeMint(address to) external;

    function getNextTokenId() external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;
}
