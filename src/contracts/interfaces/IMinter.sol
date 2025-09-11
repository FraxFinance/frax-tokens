pragma solidity ^0.8.0;

interface IMinter {
    // state variables
    function minters_array(uint256) external view returns (address);
    function minters(address) external view returns (bool);

    // state changers
    function minter_burn_from(address b_address, uint256 b_amount) external;
    function minter_mint(address m_address, uint256 m_amount) external;
    function addMinter(address minter_address) external;
    function removeMinter(address minter_address) external;

    // errors
    error OnlyMinters();

    // events
    event MinterAdded(address minter_address);
    event MinterRemoved(address minter_address);
    event TokenMinterBurned(address indexed from, address indexed to, uint256 amount);
    event TokenMinterMinted(address indexed from, address indexed to, uint256 amount);
}
