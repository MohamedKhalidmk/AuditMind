pragma solidity ^0.5.16;

interface ERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract CollateralsWallet {

	address public holdefiContract;

	
	function setHoldefiContract(address holdefiContractAddress) external {
		require (holdefiContract == address(0),'Should be set once');
		holdefiContract = holdefiContractAddress;
	}
	
	
	function withdraw (address collateralAsset, address payable recipient, uint amount) external {
		require (msg.sender == holdefiContract,'Sender should be holdefi contract');
		
		if (collateralAsset == address(0)){
			recipient.transfer(amount);
		}
		else {
			ERC20 token = ERC20(collateralAsset);
			bool success = token.transfer(recipient, amount);
			require (success, 'Cannot Transfer Token');
		}
	}

	function () payable external {
		require (msg.sender == holdefiContract,'Sender should be holdefi contract');
	}
}