


pragma solidity ^0.8.26;

import {IERC7802} from "../../interfaces/draft-IERC7802.sol";
import {BridgeFungible} from "./abstract/BridgeFungible.sol";



abstract contract BridgeERC7802 is BridgeFungible {
    IERC7802 private immutable _token;

    constructor(IERC7802 token_) {
        _token = token_;
    }

    
    function token() public view virtual returns (IERC7802) {
        return _token;
    }

    
    function _onSend(address from, uint256 amount) internal virtual override {
        token().crosschainBurn(from, amount);
    }

    
    function _onReceive(address to, uint256 amount) internal virtual override {
        token().crosschainMint(to, amount);
    }
}
