;; YieldTracker Contract
;; Allows users to deposit STX and track yield over time

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-minimum-deposit (err u102))
(define-constant err-no-position (err u103))
(define-constant err-invalid-amount (err u104))

;; Minimum deposit amount (1 STX)
(define-constant minimum-deposit-amount u1000000)

;; Data Variables
(define-data-var total-deposits uint u0)
(define-data-var yield-rate uint u500) ;; 5% annual yield (500 basis points)

;; Data Maps
(define-map user-deposits 
    principal 
    {
        amount: uint,
        deposit-block: uint,
        last-claim-block: uint
    }
)

(define-map user-yield-earned principal uint)

;; Read-only functions
(define-read-only (get-user-deposit (user principal))
    (map-get? user-deposits user)
)

(define-read-only (get-user-yield (user principal))
    (default-to u0 (map-get? user-yield-earned user))
)

(define-read-only (get-total-deposits)
    (var-get total-deposits)
)

(define-read-only (get-yield-rate)
    (var-get yield-rate)
)

(define-read-only (calculate-pending-yield (user principal))
    (match (map-get? user-deposits user)
        deposit-info
        (let (
            (blocks-elapsed (- block-height (get last-claim-block deposit-info)))
            (deposit-amount (get amount deposit-info))
            (annual-blocks u52560) ;; Approximate blocks per year
            (yield-amount (/ (* (* deposit-amount (var-get yield-rate)) blocks-elapsed) (* annual-blocks u10000)))
        )
        (ok yield-amount))
        (err err-no-position)
    )
)

;; Public functions
(define-public (deposit-stx (amount uint))
    (begin
        (asserts! (>= amount minimum-deposit-amount) err-minimum-deposit)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (match (map-get? user-deposits tx-sender)
            existing-deposit
            ;; Update existing deposit
            (let (
                (new-amount (+ (get amount existing-deposit) amount))
                (pending-yield-result (unwrap-panic (calculate-pending-yield tx-sender)))
            )
            (map-set user-deposits tx-sender {
                amount: new-amount,
                deposit-block: (get deposit-block existing-deposit),
                last-claim-block: block-height
            })
            (map-set user-yield-earned tx-sender 
                (+ (get-user-yield tx-sender) pending-yield-result))
            )
            ;; Create new deposit
            (map-set user-deposits tx-sender {
                amount: amount,
                deposit-block: block-height,
                last-claim-block: block-height
            })
        )
        
        (var-set total-deposits (+ (var-get total-deposits) amount))
        (ok amount)
    )
)

(define-public (withdraw-stx (amount uint))
    (let (
        (user-deposit (unwrap! (map-get? user-deposits tx-sender) err-no-position))
        (deposit-amount (get amount user-deposit))
        (pending-yield-result (unwrap-panic (calculate-pending-yield tx-sender)))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (<= amount deposit-amount) err-insufficient-balance)
    
    ;; Update user deposit
    (if (is-eq amount deposit-amount)
        ;; Full withdrawal - remove entry
        (map-delete user-deposits tx-sender)
        ;; Partial withdrawal - update amount
        (map-set user-deposits tx-sender {
            amount: (- deposit-amount amount),
            deposit-block: (get deposit-block user-deposit),
            last-claim-block: block-height
        })
    )
    
    ;; Update yield earned
    (map-set user-yield-earned tx-sender 
        (+ (get-user-yield tx-sender) pending-yield-result))
    
    ;; Update total deposits
    (var-set total-deposits (- (var-get total-deposits) amount))
    
    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (ok amount)
    )
)

(define-public (claim-yield)
    (let (
        (user-deposit (unwrap! (map-get? user-deposits tx-sender) err-no-position))
        (pending-yield-result (unwrap-panic (calculate-pending-yield tx-sender)))
        (total-yield (+ (get-user-yield tx-sender) pending-yield-result))
    )
    (asserts! (> total-yield u0) err-invalid-amount)
    
    ;; Update last claim block
    (map-set user-deposits tx-sender {
        amount: (get amount user-deposit),
        deposit-block: (get deposit-block user-deposit),
        last-claim-block: block-height
    })
    
    ;; Reset yield earned
    (map-delete user-yield-earned tx-sender)
    
    ;; Transfer yield to user (in a real implementation, this would come from protocol earnings)
    (try! (as-contract (stx-transfer? total-yield tx-sender tx-sender)))
    (ok total-yield)
    )
)

;; Owner-only functions
(define-public (set-yield-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set yield-rate new-rate)
        (ok new-rate)
    )
)