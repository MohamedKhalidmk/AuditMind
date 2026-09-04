

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract STCERC20 is ERC20 {
    
    constructor() ERC20("Student Coin", "STC") {
        _mint(_msgSender(), 10_000_000_000 * (10 ** uint256(decimals())));
    }

    function batchTransfer(address[] calldata destinations, uint256[] calldata amounts) public {
        uint256 n = destinations.length;
        address sender = _msgSender();
        require(n == amounts.length, "STCERC20: Invalid BatchTransfer");
        for(uint256 i = 0; i < n; i++)
            _transfer(sender, destinations[i], amounts[i]);
    }
}
