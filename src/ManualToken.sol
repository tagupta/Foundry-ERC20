// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ManualToken {
    error InsufficientBalance();
    error AddressZero();

    string public name = "Manual Token";
    mapping(address => uint256) private s_balances;
    uint8 decimals = 18;

    function totalSupply() public pure returns (uint256) {
        return 100 ether;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return s_balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 prevOverallBalance = balanceOf(msg.sender) + balanceOf(_to);
        uint256 prevBalance = balanceOf(msg.sender);
        if (prevBalance < _value) revert InsufficientBalance();
        if (_to == address(0)) revert AddressZero();

        s_balances[msg.sender] -= _value;
        s_balances[_to] += _value;
        require(prevOverallBalance == balanceOf(msg.sender) + balanceOf(_to), InsufficientBalance());
        success = payable(_to).send(_value);
    }
}
