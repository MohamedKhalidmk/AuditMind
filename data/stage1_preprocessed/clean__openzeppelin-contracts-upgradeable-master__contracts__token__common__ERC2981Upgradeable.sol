


pragma solidity ^0.8.20;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Upgradeable} from "../../utils/introspection/ERC165Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";


abstract contract ERC2981Upgradeable is Initializable, IERC2981, ERC165Upgradeable {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    
    struct ERC2981Storage {
        RoyaltyInfo _defaultRoyaltyInfo;
        mapping(uint256 tokenId => RoyaltyInfo) _tokenRoyaltyInfo;
    }

    
    bytes32 private constant ERC2981StorageLocation = 0xdaedc9ab023613a7caf35e703657e986ccfad7e3eb0af93a2853f8d65dd86b00;

    function _getERC2981Storage() private pure returns (ERC2981Storage storage $) {
        assembly {
            $.slot := ERC2981StorageLocation
        }
    }

    
    error ERC2981InvalidDefaultRoyalty(uint256 numerator, uint256 denominator);

    
    error ERC2981InvalidDefaultRoyaltyReceiver(address receiver);

    
    error ERC2981InvalidTokenRoyalty(uint256 tokenId, uint256 numerator, uint256 denominator);

    
    error ERC2981InvalidTokenRoyaltyReceiver(uint256 tokenId, address receiver);

    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view virtual returns (address receiver, uint256 amount) {
        ERC2981Storage storage $ = _getERC2981Storage();
        RoyaltyInfo storage _royaltyInfo = $._tokenRoyaltyInfo[tokenId];
        address royaltyReceiver = _royaltyInfo.receiver;
        uint96 royaltyFraction = _royaltyInfo.royaltyFraction;

        if (royaltyReceiver == address(0)) {
            royaltyReceiver = $._defaultRoyaltyInfo.receiver;
            royaltyFraction = $._defaultRoyaltyInfo.royaltyFraction;
        }

        uint256 royaltyAmount = Math.mulDiv(salePrice, royaltyFraction, _feeDenominator());

        return (royaltyReceiver, royaltyAmount);
    }

    
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        ERC2981Storage storage $ = _getERC2981Storage();
        uint256 denominator = _feeDenominator();
        if (feeNumerator > denominator) {
            
            revert ERC2981InvalidDefaultRoyalty(feeNumerator, denominator);
        }
        if (receiver == address(0)) {
            revert ERC2981InvalidDefaultRoyaltyReceiver(address(0));
        }

        $._defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    
    function _deleteDefaultRoyalty() internal virtual {
        ERC2981Storage storage $ = _getERC2981Storage();
        delete $._defaultRoyaltyInfo;
    }

    
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual {
        ERC2981Storage storage $ = _getERC2981Storage();
        uint256 denominator = _feeDenominator();
        if (feeNumerator > denominator) {
            
            revert ERC2981InvalidTokenRoyalty(tokenId, feeNumerator, denominator);
        }
        if (receiver == address(0)) {
            revert ERC2981InvalidTokenRoyaltyReceiver(tokenId, address(0));
        }

        $._tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        ERC2981Storage storage $ = _getERC2981Storage();
        delete $._tokenRoyaltyInfo[tokenId];
    }
}
