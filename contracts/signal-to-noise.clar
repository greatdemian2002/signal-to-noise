;; Signal-to-Noise Token Contract
;; Wallets earn tokens when their submitted data correlates with future verified truth
;; Lose tokens for misinformation

;; Token definitions
(define-fungible-token signal-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-claim-not-found (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-invalid-amount (err u104))

;; Reward and penalty amounts
(define-constant reward-amount u100)
(define-constant penalty-amount u50)
(define-constant initial-token-amount u1000)

;; Data vars
(define-data-var claim-nonce uint u0)

;; Data maps
;; Map to store user claims
(define-map claims
    uint
    {
        submitter: principal,
        claim-data: (string-ascii 256),
        block-height: uint,
        verified: bool,
        is-accurate: (optional bool)
    }
)

;; Map to track user balances and stats
(define-map user-stats
    principal
    {
        claims-submitted: uint,
        accurate-claims: uint,
        false-claims: uint
    }
)

;; Public functions

;; Initialize a user with starting tokens
(define-public (register)
    (let ((caller tx-sender))
        (if (is-none (map-get? user-stats caller))
            (begin
                (try! (ft-mint? signal-token initial-token-amount caller))
                (map-set user-stats caller {
                    claims-submitted: u0,
                    accurate-claims: u0,
                    false-claims: u0
                })
                (ok true)
            )
            (ok false)
        )
    )
)

;; Submit a claim about future verifiable data
(define-public (submit-claim (claim-data (string-ascii 256)))
    (let
        (
            (caller tx-sender)
            (claim-id (var-get claim-nonce))
        )
        ;; Auto-register if needed
        (if (is-none (map-get? user-stats caller))
            (try! (register))
            true
        )

        ;; Store the claim
        (map-set claims claim-id {
            submitter: caller,
            claim-data: claim-data,
            block-height: block-height,
            verified: false,
            is-accurate: none
        })

        ;; Update user stats
        (let ((stats (default-to
                {claims-submitted: u0, accurate-claims: u0, false-claims: u0}
                (map-get? user-stats caller))))
            (map-set user-stats caller (merge stats {
                claims-submitted: (+ (get claims-submitted stats) u1)
            }))
        )

        ;; Increment nonce
        (var-set claim-nonce (+ claim-id u1))
        (ok claim-id)
    )
)

;; Verify a claim as accurate or inaccurate (owner only for simplicity)
(define-public (verify-claim (claim-id uint) (is-accurate bool))
    (let
        (
            (claim (unwrap! (map-get? claims claim-id) err-claim-not-found))
            (submitter (get submitter claim))
        )
        ;; Only contract owner can verify (in production, use oracle or voting mechanism)
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)

        ;; Check if already verified
        (asserts! (not (get verified claim)) err-already-verified)

        ;; Update claim
        (map-set claims claim-id (merge claim {
            verified: true,
            is-accurate: (some is-accurate)
        }))

        ;; Reward or penalize
        (if is-accurate
            (begin
                ;; Reward accurate claim
                (try! (ft-mint? signal-token reward-amount submitter))
                (let ((stats (unwrap-panic (map-get? user-stats submitter))))
                    (map-set user-stats submitter (merge stats {
                        accurate-claims: (+ (get accurate-claims stats) u1)
                    }))
                )
                (ok {result: "rewarded", amount: reward-amount})
            )
            (begin
                ;; Penalize false claim
                (if (>= (ft-get-balance signal-token submitter) penalty-amount)
                    (try! (ft-burn? signal-token penalty-amount submitter))
                    ;; Burn whatever they have left
                    (try! (ft-burn? signal-token (ft-get-balance signal-token submitter) submitter))
                )
                (let ((stats (unwrap-panic (map-get? user-stats submitter))))
                    (map-set user-stats submitter (merge stats {
                        false-claims: (+ (get false-claims stats) u1)
                    }))
                )
                (ok {result: "penalized", amount: penalty-amount})
            )
        )
    )
)

;; Transfer tokens between users
(define-public (transfer (amount uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-owner-only)
        (asserts! (> amount u0) err-invalid-amount)
        (try! (ft-transfer? signal-token amount sender recipient))
        (ok true)
    )
)

;; Read-only functions

;; Get token balance
(define-read-only (get-balance (account principal))
    (ok (ft-get-balance signal-token account))
)

;; Get total supply
(define-read-only (get-total-supply)
    (ok (ft-get-supply signal-token))
)

;; Get claim details
(define-read-only (get-claim (claim-id uint))
    (ok (map-get? claims claim-id))
)

;; Get user statistics
(define-read-only (get-user-stats (user principal))
    (ok (map-get? user-stats user))
)

;; Get current claim nonce
(define-read-only (get-claim-nonce)
    (ok (var-get claim-nonce))
)

;; Calculate user reputation score (accurate claims / total claims)
(define-read-only (get-reputation (user principal))
    (let ((stats (map-get? user-stats user)))
        (match stats
            user-data
                (let ((total (get claims-submitted user-data)))
                    (if (> total u0)
                        (ok (/ (* (get accurate-claims user-data) u100) total))
                        (ok u0)
                    )
                )
            (ok u0)
        )
    )
)
