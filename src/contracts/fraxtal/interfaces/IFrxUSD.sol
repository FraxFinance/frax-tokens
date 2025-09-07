pragma solidity ^0.8.0;

import { IERC20PermitPermissionedOptiMintable } from "src/contracts/fraxtal/shared/interfaces/IERC20PermitPermissionedOptiMintable.sol";

/// @title IFrxUSD
/// @notice Interface for the frxUSD contract
interface IFrxUSD is IERC20PermitPermissionedOptiMintable {
    /// @dev state variables
    function isFrozen(address account) external view returns (bool);
    function isPaused() external view returns (bool);

    /// @dev admin functions
    function thawMany(address[] memory _owners) external;
    function thaw(address _owner) external;
    function freezeMany(address[] memory _owners) external;
    function freeze(address _owner) external;
    function burnMany(address[] memory _owners, uint256[] memory _amounts) external;
    function burnFrxUsd(address _owner, uint256 _amount) external;
    function pause() external;
    function unpause() external;

    /// @dev events
    event Paused();
    event Unpaused();
    event AccountFrozen(address account);
    event AccountThawed(address account);

    /// @dev errors
    error ArrayMisMatch();
    error IsPaused();
    error IsFrozen();
}
