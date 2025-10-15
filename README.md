# 🪙 DynamicVolumePricedToken (DVP)

**Network:** Flow EVM Testnet  
**Contract Address:** [`0xDBEF45B4C5C4C0d572EC19B67f215DD212e5a116`](https://evm-testnet.flowscan.io/address/0xDBEF45B4C5C4C0d572EC19B67f215DD212e5a116)

---

## 📖 Overview

`DynamicVolumePricedToken` (symbol: **DVP**) is an experimental ERC20-style token with a **dynamic pricing mechanism** that automatically adjusts the token price based on cumulative trading volume.

- **No imports** or **constructors** used — fully self-contained Solidity code.  
- **No input fields** for core functions — everything is automatic.  
- **Dynamic price**: increases as more tokens are bought or sold.  
- **Pure ETH-based economy** — users buy and sell tokens directly from the contract.

---

## ⚙️ Features

| Feature | Description |
|----------|--------------|
| 🧮 **Dynamic Pricing** | Token price grows linearly with total volume traded. |
| 💸 **Buy with ETH** | Call `buy()` (payable) — tokens are minted based on current price. |
| 💰 **Sell for ETH** | Call `sellAll()` — sells your full balance for ETH at the current price. |
| 🔄 **No Admin Needed** | Fully autonomous — anyone can mint via `seedMint()` for testing. |
| 🧠 **Deterministic Pricing** | Based on `basePrice + (cumulativeTokensTraded * basePrice) / slopeDenominator`. |

---

## 🧩 Contract Details

| Parameter | Value |
|------------|--------|
| **Name** | DynamicVolumePricedToken |
| **Symbol** | DVP |
| **Decimals** | 18 |
| **Base Price** | `1e15` wei (≈ 0.001 ETH per token) |
| **Slope Denominator** | `1e24` (controls how fast the price increases) |

---

## 🧠 Core Functions

### 1. `buy() payable`
Buy tokens with ETH at the current dynamic price.  
- No inputs.  
- Emits `Bought` event.

### 2. `sellAll()`
Sell **your entire token balance** for ETH at the current price.  
- No inputs.  
- Emits `Sold` event.

### 3. `currentPricePerToken() → uint256`
View the current token price (in wei).

### 4. `quoteTokensForWei(uint256 weiAmount) → uint256`
Estimate how many tokens you’d get for a given ETH amount.

### 5. `quoteWeiForTokens(uint256 tokenAmount) → uint256`
Estimate how much ETH you’d receive for a given token amount.

### 6. `seedMint()`
Mint 1000 test tokens to yourself — used for testing since no constructor exists.

---

## 💻 Example Usage (Remix or Web3)

### Buy tokens
```solidity
DynamicVolumePricedToken token = DynamicVolumePricedToken(0xDBEF45B4C5C4C0d572EC19B67f215DD212e5a116);
token.buy{value: 0.01 ether}();
