# Uniswap CLAMM

## Description:

## Notes:

### Uniswap V3 price and tick:

X = amount of token0 1 ETH
Y = amount of token1 2000 USDC

V2: P = Price of X in terms of P = Y/X = 2000/1 USDC/ETH
V3: P = 1.0001^tick^ 

In Uniswap V3 in order to calculate the price we need to know three things:
1. Liquidity
2. Price range
3. Current price

ex. ETH/USDC tick = -200697
P = 1.0001^(-200697)^

To get the price in Y token decimals => P * decimals_0 / decimals_1

### Tick spacing:

Number of ticks to skip to skip when the price moves.

ex. tick spacing = 2

current tick = 0

Price increases => tick = 2
Price increases => tick = 4