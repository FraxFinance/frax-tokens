pragma solidity ^0.8.0;

import { IFrxUSD1 } from "src/contracts/ethereum/frxUSD/versioning/IFrxUSD1.sol";

/// @title FrxUSD2 interface
interface IFrxUSD2 is IFrxUSD1 {
    function isFrozen(address account) external view returns (bool);
    function isPaused() external view returns (bool);
    function thawMany(address[] memory _owners) external;
    function thaw(address _owner) external;
    function freezeMany(address[] memory _owners) external;
    function freeze(address _owner) external;
    function burnMany(address[] memory _owners, uint256[] memory _amounts) external;
    function burn(address _owner, uint256 _amount) external;
    function pause() external;
    function unpause() external;

    event Paused();
    event Unpaused();
    event AccountFrozen(address account);
    event AccountThawed(address account);

    error OwnerCannotInitToZeroAddress();
    error ArrayMisMatch();
    error IsPaused();
    error IsFrozen();
}
