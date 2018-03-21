pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}


/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


/**
 * @title FreezableToken
 */
contract FreezableToken is StandardToken, Ownable {
    mapping (address => bool) public frozenAccounts;
    event FrozenFunds(address target, bool frozen);

    function freezeAccount(address target) public onlyOwner {
        frozenAccounts[target] = true;
        FrozenFunds(target, true);
    }

    function unFreezeAccount(address target) public onlyOwner {
        frozenAccounts[target] = false;
        FrozenFunds(target, false);
    }

    function frozen(address _target) constant public returns (bool){
        return frozenAccounts[_target];
    }

    // @dev Limit token transfer if _sender is frozen.
    modifier canTransfer(address _sender) {
        require(!frozenAccounts[_sender]);
        _;
    }

    function transfer(address _to, uint256 _value) public canTransfer(msg.sender) returns (bool success) {
        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer(_from) returns (bool success) {
        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }
}


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


/**
 * @title LogiqTokenCrowdsale
 */
contract LogiqTokenCrowdsale is Ownable {

    using SafeMath for uint256;

    ERC20 public token; // The token being sold

    mapping(address => Contributor) public contributors;

    address[] addresses;  //Array of the addresses who participated

    uint256 public stage = 0;
    uint256 public weiDelivered = 0;
    uint256 public tokensSold = 0;
    uint256 public buyPrice = 1 ether;               // start price 1 Token = 1 ETH, will change after crowdsale start
    uint256 public ICOdeadLine = 1530392400;         // ICO end time - Sunday, 1 July 2018, 00:00:00.

    uint256 public constant softcap = 85000000 ether;
    uint256 public constant hardcap = 420000000 ether;

    uint256 availableTokens = hardcap;

    bool public softcapReached;
    bool public refundIsAvailable;
    bool public burned;

    event SoftcapReached();
    event HardcapReached();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event CrowdSaleFinished(string info);
    event Burned(address indexed burner, uint256 amount);

    modifier afterDeadline {
        require(now > ICOdeadLine);
        _;
    }

    struct Contributor {
        uint256 eth;                // Contributor ETH
        bool whitelisted;           // White list true/false
        bool created;               // is contributor added
        uint256 ethDeposit;
    }

    struct Ico {
        uint256 tokens;             // Tokens in crowdsale
        uint startDate;             // Date when crowsale will be starting, after its starting that property will be the 0
        uint endDate;               // Date when crowdsale will be stop
        uint8 discount;             // Discount
        uint8 discountFirstDayICO;  // Discount. Only for first stage ico
    }

    Ico public ICO;

    function LogiqTokenCrowdsale() public {
        token = new LogiqToken();
    }

    /**
     * @dev fallback function
     */
    function () external payable {
        require(now < ICOdeadLine);
        require(ICO.startDate <= now);
        require(ICO.endDate > now);
        require(ICO.tokens != 0);

        buyTokens(msg.sender);
    }

    /**
     * @dev token purchase
     * @param _contributor Address performing the token purchase
     */
    function buyTokens(address _contributor) public payable {
        require(_contributor != address(0));
        require(msg.value != 0);
        require(msg.value >= ( 1 ether / 100));

        _forwardFunds();
    }

    function _forwardFunds() internal {
        Contributor storage contributor = contributors[msg.sender];

        contributor.eth = contributor.eth.add(msg.value);
        contributor.ethDeposit = contributor.ethDeposit.add(msg.value);

        if (contributor.created == false) {
            contributor.created = true;
            addresses.push(msg.sender);
        }

        if (contributor.whitelisted) {
            _deliverTokens(msg.sender);
        }
    }

    function _deliverTokens(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];

        uint256 amountEth = contributor.eth;
        uint256 amountToken = _getTokenAmount(amountEth);

        require(confirmSell(amountToken));
        require(amountEth > 0);
        require(amountToken > 0);

        require(contributor.whitelisted);

        contributor.eth = 0;
        weiDelivered = weiDelivered.add(amountEth);
        tokensSold = tokensSold.add(amountToken);
        availableTokens = availableTokens.sub(amountToken);
        ICO.tokens = ICO.tokens.sub(amountToken);

        token.transfer(_contributor, amountToken);

        if ((tokensSold >= softcap) && !softcapReached) {
            softcapReached = true;
            SoftcapReached();
        }

        if (tokensSold == hardcap) {
            HardcapReached();
            CrowdSaleFinished(crowdSaleStatus());
        }

    }

    function confirmSell(uint256 _amount) internal view returns(bool) {
        if (ICO.tokens < _amount) {
            return false;
        }

        return true;
    }

    function crowdSaleStatus() public constant returns (string) {
        if (1 == stage) {
            return "Private sale";
        }
        else if(2 == stage) {
            return "Pre-ICO";
        }
        else if (3 == stage) {
            return "ICO first stage";
        }
        else if (4 == stage) {
            return "ICO second stage";
        }
        else if (5 >= stage) {
            return "feature stage";
        }

        return "there is no stage at present";
    }

    function _changeDiscount(uint8 _discount) public onlyOwner returns (bool) {
        ICO = Ico (ICO.tokens, ICO.startDate, ICO.endDate, _discount, ICO.discountFirstDayICO);
        return true;
    }

    function _changeRate(uint256 _numerator, uint256 _denominator) public onlyOwner returns (bool success) {
        if (_numerator == 0) _numerator = 1;
        if (_denominator == 0) _denominator = 1;

        buyPrice = (_numerator * 1 ether).div(_denominator);

        return true;
    }

    /**
     * @dev the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 weiAmount = (_weiAmount * 1 ether).div(buyPrice);

        require(weiAmount > 0);

        if (1 == stage) {
            weiAmount = weiAmount.add(_withDiscount(weiAmount, ICO.discount));
        }
        else if (2 == stage) {
            weiAmount = weiAmount.add(_withDiscount(weiAmount, ICO.discount));
        }
        else if (3 == stage) {
            if (now <= ICO.startDate + 1 days) {
                weiAmount = weiAmount.add(_withDiscount(weiAmount, ICO.discountFirstDayICO));
            } else {
                weiAmount = weiAmount.add(_withDiscount(weiAmount, ICO.discount));
            }
        }
        else if (4 == stage) {
            weiAmount = weiAmount.add(_withDiscount(weiAmount, ICO.discount));
        }

        return weiAmount;
    }

    function _withDiscount(uint256 _amount, uint _percent) internal pure returns (uint256){
        return (_amount.mul(_percent)).div(100);
    }

    function _refundTokens(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];

        uint256 ethAmount = contributor.eth;
        require(ethAmount > 0);

        contributor.eth = 0;
        contributor.ethDeposit = 0;

        _contributor.transfer(ethAmount);
    }

    function _whitelistAddress(address _contributor) internal {
        Contributor storage contributor = contributors[_contributor];

        contributor.whitelisted = true;
        if (contributor.created == false) {
            contributor.created = true;
            addresses.push(_contributor);
        }
        //Auto deliver tokens
        if (contributor.eth > 0) {
            _deliverTokens(_contributor);
        }
    }

    /**********************owner*************************/
    function whitelistAddresses(address[] _contributors) public onlyOwner {
        for (uint256 i = 0; i < _contributors.length; i++) {
            _whitelistAddress(_contributors[i]);
        }
    }

    function whitelistAddress(address _contributor) public onlyOwner {
        _whitelistAddress(_contributor);
    }

    function transferTokenOwnership(address _newOwner) public onlyOwner returns(bool success) {
        LogiqToken _token = LogiqToken(token);
        _token.transferOwnership(_newOwner);
        return true;
    }

    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        require(softcapReached);
        _to.transfer(amount);
    }

    function startCrowd(
        uint256 _tokens,
        uint _startDate,
        uint _endDate,
        uint8 _discount,
        uint8 _discountFirstDayICO) public onlyOwner {
        require(( _tokens * 1 ether ) <= availableTokens);
        ICO = Ico (_tokens * 1 ether, _startDate, _endDate, _discount, _discountFirstDayICO); // _startDate + _endDate * 1 days
        stage = stage.add(1);
    }

    /**
     * @dev Refound tokens. For owner
     */
    function refundTokensForAddress(address _contributor) public onlyOwner {
        _refundTokens(_contributor);
    }

    /**********************contributor*************************/
    function getAddresses() public onlyOwner view returns (address[] )  {
        return addresses;
    }

    /**
    * @dev Refound tokens. For contributors
    */
    function refundTokens() public {
        _refundTokens(msg.sender);
    }

    /**
     * @dev Returns tokens according to rate
     */
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
        return _getTokenAmount(_weiAmount);
    }

    function enableRefundAfterICO() public afterDeadline {
        require(!softcapReached);

        refundIsAvailable = true;
        RefundsEnabled();
    }

    function getRefundAfterICO() public afterDeadline {
        Contributor storage contributor = contributors[msg.sender];

        require(refundIsAvailable);
        require(contributor.ethDeposit > 0);

        uint256 depositedValue = contributor.ethDeposit;
        contributor.ethDeposit = 0;
        msg.sender.transfer(depositedValue);

        Refunded(msg.sender, depositedValue);
    }

}
