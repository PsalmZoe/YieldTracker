YieldTracker
A simple Stacks smart contract for earning yield on STX deposits.
What it does
YieldTracker lets you deposit STX tokens and earn a 5% annual yield. Your yield grows over time based on how long you keep your tokens deposited.
How to use
Deposit STX

Minimum deposit: 1 STX
Your yield starts earning immediately
You can make multiple deposits

Withdraw STX

Withdraw any amount up to your total deposit
Your remaining balance keeps earning yield
No penalties or lock-up periods

Claim Yield

Claim your earned yield at any time
Yield is calculated based on blocks elapsed
Approximately 5% annual return

Functions
For Users:

deposit-stx - Deposit STX to start earning yield
withdraw-stx - Withdraw your deposited STX
claim-yield - Claim your earned yield
get-user-deposit - Check your deposit amount
calculate-pending-yield - See how much yield you've earned

For Contract Owner:

set-yield-rate - Adjust the annual yield rate

Example
clarity;; Deposit 10 STX
(contract-call? .yield-tracker deposit-stx u10000000)

;; Check your deposit
(contract-call? .yield-tracker get-user-deposit tx-sender)

;; Claim your yield
(contract-call? .yield-tracker claim-yield)
Technical Details

Yield Rate: 5% annually (500 basis points)
Minimum Deposit: 1 STX (1,000,000 microSTX)
Yield Calculation: Based on Stacks block height
No Lock-up: Withdraw anytime

Important Notes

This is a basic implementation for demonstration purposes
The contract doesn't specify how yield payments are funded in production
Always test thoroughly before using with real funds
Only the contract owner can change yield rates
