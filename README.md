Signal-to-Noise Token (SNT) Smart Contract

Overview

The Signal-to-Noise Token (SNT) contract is a Stacks smart contract designed to incentivize users to submit truthful, verifiable claims about future events or data. Users earn SNT tokens for accurate claims and lose tokens for false or inaccurate claims. The system tracks each user's statistics, enabling the calculation of a reputation score based on claim accuracy.

This contract is ideal for applications like decentralized prediction markets, reputation systems, or crowdsourced forecasting platforms.

Features

Token Management

Mint and burn signal-token (SNT) for user rewards and penalties.

Transfer tokens between users.

Track balances and total supply.

User Registration

Users auto-register upon their first claim or manually via register.

Each user starts with an initial token allocation.

Claims System

Users submit claims about future verifiable data.

Claims include data, submitter, block-height, verification status, and accuracy.

Each claim is assigned a unique claim-id via an incrementing nonce.

Verification

Contract owner verifies claims as accurate or false (in production, can be replaced with oracle or voting).

Accurate claims earn rewards, false claims incur penalties.

User statistics are updated automatically.

Reputation System

Calculates a user’s reputation as the percentage of accurate claims relative to total submitted claims.

Read-Only Queries

Retrieve token balances, total supply, claim details, user statistics, and reputation scores.

Data Structures

claims map

Key: uint (claim-id)

Value: { submitter: principal, claim-data: string-ascii 256, block-height: uint, verified: bool, is-accurate: optional bool }

user-stats map

Key: principal (user wallet)

Value: { claims-submitted: uint, accurate-claims: uint, false-claims: uint }

claim-nonce

Auto-incrementing counter for generating unique claim IDs.

Constants
Constant	Description
reward-amount	Tokens awarded for accurate claims (100 SNT)
penalty-amount	Tokens burned for false claims (50 SNT)
initial-token-amount	Tokens granted upon registration (1000 SNT)
contract-owner	Principal that deployed the contract
err-*	Predefined error codes for ownership, balance, and claim validation
Functions
Public Functions

register(): Register a user and mint initial tokens.

submit-claim(claim-data): Submit a claim; auto-registers user if needed.

verify-claim(claim-id, is-accurate): Owner verifies a claim and rewards/penalizes the submitter.

transfer(amount, sender, recipient): Transfer tokens from sender to recipient (owner-signed).

Read-Only Functions

get-balance(account): Returns user's token balance.

get-total-supply(): Returns total SNT supply.

get-claim(claim-id): Returns details of a specific claim.

get-user-stats(user): Returns the user's claim statistics.

get-claim-nonce(): Returns the next available claim ID.

get-reputation(user): Calculates reputation as (accurate claims / total claims) * 100.

Usage Example

Register a user

(register)


Submit a claim

(submit-claim "Bitcoin price > $100k by 2026")


Verify a claim (owner only)

(verify-claim 0 true)


Check user reputation

(get-reputation tx-sender)


Transfer tokens

(transfer u50 tx-sender recipient-principal)

Security Notes

Currently, claim verification is owner-only for simplicity; production systems should integrate decentralized verification via oracles or community voting.

Token burning ensures users cannot submit repeated false claims without consequences.

Reputation is transparent and on-chain, allowing trustless verification of historical accuracy.