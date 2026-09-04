
pragma solidity ^0.8.10;

import {Errors} from '../libraries/helpers/Errors.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleSentinel} from '../../interfaces/IPriceOracleSentinel.sol';
import {ISequencerOracle} from '../../interfaces/ISequencerOracle.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';


contract PriceOracleSentinel is IPriceOracleSentinel {
  
  modifier onlyPoolAdmin() {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  
  modifier onlyRiskOrPoolAdmins() {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(
      aclManager.isRiskAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
    );
    _;
  }

  IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

  ISequencerOracle internal _sequencerOracle;

  uint256 internal _gracePeriod;

  
  constructor(IPoolAddressesProvider provider, ISequencerOracle oracle, uint256 gracePeriod) {
    ADDRESSES_PROVIDER = provider;
    _sequencerOracle = oracle;
    _gracePeriod = gracePeriod;
  }

  
  function isBorrowAllowed() public view override returns (bool) {
    return _isUpAndGracePeriodPassed();
  }

  
  function isLiquidationAllowed() public view override returns (bool) {
    return _isUpAndGracePeriodPassed();
  }

  
  function _isUpAndGracePeriodPassed() internal view returns (bool) {
    (, int256 answer, , uint256 lastUpdateTimestamp, ) = _sequencerOracle.latestRoundData();
    return answer == 0 && block.timestamp - lastUpdateTimestamp > _gracePeriod;
  }

  
  function setSequencerOracle(address newSequencerOracle) public onlyPoolAdmin {
    _sequencerOracle = ISequencerOracle(newSequencerOracle);
    emit SequencerOracleUpdated(newSequencerOracle);
  }

  
  function setGracePeriod(uint256 newGracePeriod) public onlyRiskOrPoolAdmins {
    _gracePeriod = newGracePeriod;
    emit GracePeriodUpdated(newGracePeriod);
  }

  
  function getSequencerOracle() public view returns (address) {
    return address(_sequencerOracle);
  }

  
  function getGracePeriod() public view returns (uint256) {
    return _gracePeriod;
  }
}
