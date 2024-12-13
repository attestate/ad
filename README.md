# Ad

## How does it work?

This contract will give you access to set an ad on https://kiwinews.xyz. The ad will be, for example, permanently available as the top fourth link here:

![image](https://github.com/user-attachments/assets/62fae391-6eca-4959-ac72-f225f19b877e)

At the time of writing, we reach roughly 150-400 individuals in the crypto space a day. But we have no idea how much it'd be worth to advertise to these people, hence the smart contract. It'll help us do price discovery. So how does it work?

Basically, you can stake an amount of ETH for the contract to be yours. Say you stake 1 ETH, then you'll get to set the title, link, and you'll own the contract. But over 1 month, we'll charge you 1 ETH in fees (100% of the collateral a month). The ETH staked as collateral in the contract is also the price someone has to pay to acquire the ad from you. Here's an example:

- Day 0: You stake 1 ETH in collateral. The price to transfer the ad is 1 ETH.
- Day 15 (half a month): Now half of your collateral was taxed (0.5 ETH). The price to transfer the ad is 0.5 ETH. Your remaining collateral is 0.5 ETH.
- Day 30 (month): Your ad is about to be taken off the website. In case noone has bought yet, your collateral now is very low 0.0000...1 ETH, and so for someone else to buy the ad space from you is extremely cheap.

Now, what would happen if someone bought your ad for 0.9 ETH on Day 15?

1. The contract sends your leftover collateral back to you (0.5 ETH).
2. The buyer's transfer fee of 0.5 ETH is sent to you too.
3. The remainder of the buyer's value (0.4 ETH) is staked as collateral and is the new price (0.4 ETH) to transfer the ad.
4. The taxed collateral (0.5 ETH) is sent the the Kiwi News treasury.

Here are the account balances of everyone:

- You: 1 ETH
- Ad contract: 0.4 ETH (buyer's collateral)
- Kiwi News treasury: 0.5 ETH

You may have heard of this concept earlier. It's often referred to as Harberger taxes, or Partial common ownership. Check out this talk from Devcon SEA about ["Demand-based recurring fees in practice"](https://www.youtube.com/watch?v=pjcP-P7q5mU) to learn more.

### How to buy the ad?

Go to https://news.kiwistand.com/submit and check "Submit as an ad."

## Deployment

CREATE2 is used to deploy the contract to a deterministic address independent
  of chainId.
- `DEPLOYER`: 0x0000000000ffe8b47b3e2130213b802212439497
- `SALT`: 0x0000000000000000000000000000000000000000f00df00df00df00df00df00d
- `INITCODE`: 
- `ADDRESS`: 
- Deployed to:
  - Optimism

## Updates and verifying on Etherscan

```
ETHERSCAN_API_KEY=abc forge verify-contract address Ad --watch --chain 10
```

## License

SPDX-License-Identifier: AGPL-3.0
