// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// DynamicVolumePricedToken
// - No imports
// - No constructor
// - Buy with buy() payable (no inputs)
// - Sell entire balance with sellAll() (no inputs)
// - Standard ERC20-like functions (transfer, approve, transferFrom)
// - Price per token (wei) increases linearly with cumulative volume of tokens bought

contract DynamicVolumePricedToken {
    string public name = "DynamicVolumePricedToken";
    string public symbol = "DVP";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Pricing parameters (tweak these to change price behavior)
    // basePrice: starting price in wei per token (with token decimals)
    // slopeDenominator: larger => slower price growth per token volume
    uint256 public basePrice = 1e15; // 0.001 ETH per token (in wei)
    uint256 public slopeDenominator = 1e24; // controls how fast price rises with volume

    // cumulative tokens traded (bought via buy() and sold via sellAll())
    uint256 public cumulativeTokensTraded;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Bought(address indexed buyer, uint256 weiSpent, uint256 tokensReceived, uint256 pricePerToken);
    event Sold(address indexed seller, uint256 tokensSold, uint256 weiReceived, uint256 pricePerToken);

    // ---------- ERC20 basics (no constructor, no imports) ----------
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "mint to zero");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "burn from zero");
        require(balanceOf[from] >= amount, "insufficient balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "transfer to zero");
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), "transfer to zero");
        require(balanceOf[from] >= amount, "insufficient balance");
        require(allowance[from][msg.sender] >= amount, "allowance exceeded");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // ---------- Pricing logic ----------
    // Current price per token in wei (integer). We use a simple linear model:
    // price = basePrice + (cumulativeTokensTraded * basePrice) / slopeDenominator
    // This keeps price in wei and grows as more tokens are traded.
    function currentPricePerToken() public view returns (uint256) {
        // price growth term = (cumulativeTokensTraded * basePrice) / slopeDenominator
        uint256 growth = (cumulativeTokensTraded * basePrice) / slopeDenominator;
        return basePrice + growth;
    }

    // Buy tokens by sending ETH. No input fields: buy() is payable and mints tokens
    // to the msg.sender based on the current price at the time of the call.
    function buy() public payable {
        require(msg.value > 0, "send ETH to buy");
        uint256 price = currentPricePerToken();
        require(price > 0, "invalid price");

        // tokens to mint = msg.value * (10**decimals) / price
        uint256 tokens = (msg.value * (10 ** uint256(decimals))) / price;
        require(tokens > 0, "insufficient ETH for 1 token at current price");

        // update volume and mint
        cumulativeTokensTraded += tokens;
        _mint(msg.sender, tokens);

        emit Bought(msg.sender, msg.value, tokens, price);
    }

    // Sell entire token balance of caller for ETH at current price (no input fields)
    // For simplicity this function sells the caller's full token balance.
    function sellAll() public {
        uint256 tokens = balanceOf[msg.sender];
        require(tokens > 0, "no tokens to sell");

        uint256 price = currentPricePerToken();
        require(price > 0, "invalid price");

        // wei to send = tokens * price / (10**decimals)
        uint256 weiAmount = (tokens * price) / (10 ** uint256(decimals));
        require(address(this).balance >= weiAmount, "contract has insufficient ETH");

        // update state then transfer ETH
        cumulativeTokensTraded += tokens;
        _burn(msg.sender, tokens);

        // Use call to transfer ETH
        (bool ok, ) = msg.sender.call{value: weiAmount}("");
        require(ok, "ETH transfer failed");

        emit Sold(msg.sender, tokens, weiAmount, price);
    }

    // Fallback: accept ETH so contract can hold a reserve for sell backs
    receive() external payable {}

    fallback() external payable {}

    // ---------- Helper / Admin-free utilities ----------
    // Anyone can seed the contract with initial tokens for testing by calling seedMint()
    // This avoids needing a constructor. seedMint mints a small amount to caller.
    function seedMint() public returns (bool) {
        // limit seed to small amount per caller to prevent abuse
        uint256 amount = 1000 * (10 ** uint256(decimals));
        _mint(msg.sender, amount);
        return true;
    }

    // Allow viewers to quote how many tokens they'd receive for a given ETH amount
    // (read-only helper; does not accept inputs that change state)
    function quoteTokensForWei(uint256 weiAmount) public view returns (uint256) {
        uint256 price = currentPricePerToken();
        if (price == 0) return 0;
        return (weiAmount * (10 ** uint256(decimals))) / price;
    }

    // Allow viewers to quote how much ETH they'd get for selling given token amount
    function quoteWeiForTokens(uint256 tokenAmount) public view returns (uint256) {
        uint256 price = currentPricePerToken();
        return (tokenAmount * price) / (10 ** uint256(decimals));
    }
}

