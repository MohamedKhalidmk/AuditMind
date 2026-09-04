
pragma solidity >=0.5.0;



interface IMorphoLiquidateCallback {
    
    
    
    
    function onMorphoLiquidate(uint256 repaidAssets, bytes calldata data) external;
}



interface IMorphoRepayCallback {
    
    
    
    
    function onMorphoRepay(uint256 assets, bytes calldata data) external;
}



interface IMorphoSupplyCallback {
    
    
    
    
    function onMorphoSupply(uint256 assets, bytes calldata data) external;
}



interface IMorphoSupplyCollateralCallback {
    
    
    
    
    function onMorphoSupplyCollateral(uint256 assets, bytes calldata data) external;
}



interface IMorphoFlashLoanCallback {
    
    
    
    
    function onMorphoFlashLoan(uint256 assets, bytes calldata data) external;
}
