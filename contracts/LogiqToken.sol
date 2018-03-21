pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./FreezableToken.sol";

/**
 * @title LogiqToken
 */
contract LogiqToken is FreezableToken, PausableToken, BurnableToken {
    string public name = "CryptologiQ";
    string public symbol = "LOGIQ";
    uint8 public decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 700000000 ether;

    address public companyWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address public internalExchangeWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address public bountyWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address public tournamentsWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function LogiqToken() public {
        totalSupply_ = INITIAL_SUPPLY;

        balances[msg.sender] = (totalSupply_.mul(60)).div(100);              // Send 60% of tokens to smart contract wallet      420,000,000 LOGIQ
        balances[companyWallet] = (totalSupply_.mul(20)).div(100);           // Send 20% of tokens to company wallet             140,000,000 LOGIQ
        balances[internalExchangeWallet] = (totalSupply_.mul(10)).div(100);  // Send 10% of tokens to internal exchange wallet   70,000,000 LOGIQ
        balances[bountyWallet] = (totalSupply_.mul(5)).div(100);             // Send 5%  of tokens to bounty wallet              35,000,000 LOGIQ
        balances[tournamentsWallet] = (totalSupply_.mul(5)).div(100);        // Send 5%  of tokens to tournaments wallet         35,000,000 LOGIQ
    }

    function currentOwner() public view returns(address) {
        return owner;
    }
}
