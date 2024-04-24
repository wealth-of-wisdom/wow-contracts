/// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {WOWToken} from "../../contracts/WOWToken.sol";

contract TokenMock is WOWToken {
    bytes32 private constant NoncesStorageLocation =
        0x5ab42ced628888259c08ac98db1eb0cf702fc1501344311d8b100cd1bfe4bb00;

    function useNonce(address owner) external returns (uint256) {
        return _useNonce(owner);
    }

    function authorizeUpgrade(address newImplementation) external {
        _authorizeUpgrade(newImplementation);
    }
}
