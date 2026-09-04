


pragma solidity ^0.8.24;

import {Governor} from "../Governor.sol";
import {Math} from "../../utils/math/Math.sol";


abstract contract GovernorPreventLateQuorum is Governor {
    uint48 private _voteExtension;

    mapping(uint256 proposalId => uint48) private _extendedDeadlines;

    
    event ProposalExtended(uint256 indexed proposalId, uint64 extendedDeadline);

    
    event LateQuorumVoteExtensionSet(uint64 oldVoteExtension, uint64 newVoteExtension);

    
    error GovernorPreventLateQuorumVoteExtensionTooLarge(uint256 newVoteExtension, uint256 maxVoteExtension);

    
    constructor(uint48 initialVoteExtension) {
        _setLateQuorumVoteExtension(initialVoteExtension);
    }

    
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return Math.max(super.proposalDeadline(proposalId), _extendedDeadlines[proposalId]);
    }

    
    function _tallyUpdated(uint256 proposalId) internal virtual override {
        super._tallyUpdated(proposalId);
        if (_extendedDeadlines[proposalId] == 0 && _quorumReached(proposalId)) {
            uint48 extendedDeadline = clock() + lateQuorumVoteExtension();

            if (extendedDeadline > proposalDeadline(proposalId)) {
                emit ProposalExtended(proposalId, extendedDeadline);
            }

            _extendedDeadlines[proposalId] = extendedDeadline;
        }
    }

    
    function lateQuorumVoteExtension() public view virtual returns (uint48) {
        return _voteExtension;
    }

    
    function _maxLateQuorumVoteExtension() internal view virtual returns (uint256) {
        return votingPeriod();
    }

    
    function setLateQuorumVoteExtension(uint48 newVoteExtension) public virtual onlyGovernance {
        _setLateQuorumVoteExtension(newVoteExtension);
    }

    
    function _setLateQuorumVoteExtension(uint48 newVoteExtension) internal virtual {
        uint256 maxVoteExtension = _maxLateQuorumVoteExtension();
        if (newVoteExtension > maxVoteExtension) {
            revert GovernorPreventLateQuorumVoteExtensionTooLarge(newVoteExtension, maxVoteExtension);
        }
        emit LateQuorumVoteExtensionSet(_voteExtension, newVoteExtension);
        _voteExtension = newVoteExtension;
    }
}
