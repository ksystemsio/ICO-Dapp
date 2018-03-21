pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./LogiqToken.sol";

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