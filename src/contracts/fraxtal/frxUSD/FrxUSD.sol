pragma solidity ^0.8.0;

import { ERC20PermitPermissionedOptiMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedOptiMintable.sol";

contract FrxUSD is ERC20PermitPermissionedOptiMintable {
    /// @notice Mapping indicating which addresses are frozen
    mapping(address => bool) public isFrozen;

    /// @notice Whether or not the contract is paused
    bool public isPaused;

    /// @param _creator_address The contract creator
    /// @param _timelock_address The timelock
    /// @param _bridge Address of the L2 standard bridge
    /// @param _remoteToken Address of the corresponding L1 token
    constructor(
        address _creator_address,
        address _timelock_address,
        address _bridge,
        address _remoteToken
    )
        ERC20PermitPermissionedOptiMintable(
            _creator_address,
            _timelock_address,
            _bridge,
            _remoteToken,
            "Frax USD",
            "frxUSD"
        )
    {}

    /// @notice External admin gated function to unfreeze a set of accounts
    /// @param _owners Array of accounts to be unfrozen
    function thawMany(address[] memory _owners) external onlyOwner {
        uint256 len = _owners.length;
        for (uint256 i; i < len; ++i) {
            _thaw(_owners[i]);
        }
    }

    /// @notice External admin gated function to unfreeze an account
    /// @param _owner The account to be unfrozen
    function thaw(address _owner) external onlyOwner {
        _thaw(_owner);
    }

    /// @notice External admin gated function to batch freeze a set of accounts
    /// @param _owners Array of accounts to be frozen
    function freezeMany(address[] memory _owners) external onlyOwner {
        uint256 len = _owners.length;
        for (uint256 i; i < len; ++i) {
            _freeze(_owners[i]);
        }
    }

    /// @notice External admin gated function to freeze a given account
    /// @param _owner The account to be
    function freeze(address _owner) external onlyOwner {
        _freeze(_owner);
    }

    /// @notice External admin gated function to batch burn balance from a set of accounts
    /// @param _owners Array of accounts whose balances will be burned
    /// @param _amounts Array of amounts corresponding to the balances to be burned
    /// @dev if `_amount` == 0, entire balance will be burned
    function burnMany(address[] memory _owners, uint256[] memory _amounts) external onlyOwner {
        uint256 lenOwner = _owners.length;
        if (_owners.length != _amounts.length) revert ArrayMisMatch();
        for (uint256 i; i < lenOwner; ++i) {
            if (_amounts[i] == 0) _amounts[i] = balanceOf(_owners[i]);
            _burn(_owners[i], _amounts[i]);
        }
    }

    /// @notice External admin gated function to burn balance from a given account
    /// @param _owner  The account whose balance will be burned
    /// @param _amount The amount of balance to burn
    /// @dev if `_amount` == 0, entire balance will be burned
    function burnFrxUsd(address _owner, uint256 _amount) external onlyOwner {
        if (_amount == 0) _amount = balanceOf(_owner);
        _burn(_owner, _amount);
    }

    /// @notice External admin gated pause function
    function pause() external onlyOwner {
        isPaused = true;
        emit Paused();
    }

    /// @notice External admin gated unpause function
    function unpause() external onlyOwner {
        isPaused = false;
        emit Unpaused();
    }

    /* ========== Internals For Admin Gated ========== */

    /// @notice Internal helper function to freeze an account
    /// @param _owner The account to 'frozen'
    function _freeze(address _owner) internal {
        isFrozen[_owner] = true;
        emit AccountFrozen(_owner);
    }

    /// @notice Internal helper function to unfreeze an account
    /// @param _owner The account to unfreeze
    function _thaw(address _owner) internal {
        isFrozen[_owner] = false;
        emit AccountThawed(_owner);
    }

    /* ========== Overrides ========== */

    /// @notice override for base internal `_update(address,address,uint256)`
    ///         implements `paused` and `frozen` transfer logic
    /// @param from  The address from which balance is originating
    /// @param to    The address whose balance will be incremented
    /// @param value The amount to increment/decrement the balances of
    /// @dev Owner can bypass pause and freeze checks
    function _update(address from, address to, uint256 value) internal override {
        if (msg.sender != owner) {
            if (isPaused) revert IsPaused();
            if (isFrozen[to] || isFrozen[from] || isFrozen[msg.sender]) revert IsFrozen();
        }
        super._update(from, to, value);
    }

    /* ========== EVENTS ========== */
    /// @notice Event Emitted when the contract is paused
    event Paused();

    /// @notice Event Emitted when the contract is unpaused
    event Unpaused();

    /// @notice Event Emitted when an address is frozen
    /// @param account The account being frozen
    event AccountFrozen(address account);

    /// @notice Event Emitted when an address is unfrozen
    /// @param account The account being thawed
    event AccountThawed(address account);

    /* ========== ERRORS ========== */
    error ArrayMisMatch();
    error IsPaused();
    error IsFrozen();
}
