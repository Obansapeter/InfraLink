;; ================================================
;; InfraLink - Decentralized Physical Infra Staking
;; ================================================

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_REGISTERED (err u102))
(define-constant ERR_INSUFFICIENT_STAKE (err u103))
(define-constant ERR_TOO_SOON (err u104))
(define-constant ERR_NOT_ACTIVE (err u105))
(define-constant ERR_NOT_ELIGIBLE (err u106))

(define-constant MIN_STAKE_AMOUNT u10000000) ;; 0.1 STX
(define-constant REWARD_INTERVAL u144) ;; Approx. 24 hrs
(define-constant REWARD_AMOUNT u1000000) ;; 0.01 STX
(define-constant COOLDOWN_BLOCKS u288) ;; 2 days

(define-constant oracle-admin 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) ;; replace with real one

(define-map nodes principal {
    staked: uint,
    last-claim: uint,
    active: bool,
    last-online: uint,
    cooldown-start: (optional uint)
})

(define-data-var total-staked uint u0)

;; ---------------------------
;; Register Node
;; ---------------------------
(define-public (register-node)
    (begin
        (if (is-some (map-get? nodes tx-sender))
            (err ERR_ALREADY_REGISTERED)
            (begin
                (map-set nodes tx-sender {
                    staked: u0,
                    last-claim: burn-block-height,
                    active: false,
                    last-online: u0,
                    cooldown-start: none
                })
                (ok true)
            )
        )
    )
)

;; ---------------------------
;; Stake STX
;; ---------------------------
(define-public (stake)
    (let ((node (map-get? nodes tx-sender)))
        (match node
            node-data
            (begin
                (match (stx-transfer? MIN_STAKE_AMOUNT tx-sender (as-contract tx-sender))
                    success-tx
                    (begin
                        (map-set nodes tx-sender {
                            staked: (+ (get staked node-data) MIN_STAKE_AMOUNT),
                            last-claim: burn-block-height,
                            active: true,
                            last-online: burn-block-height,
                            cooldown-start: none
                        })
                        (var-set total-staked (+ (var-get total-staked) MIN_STAKE_AMOUNT))
                        (ok true)
                    )
                    error (err ERR_INSUFFICIENT_STAKE)
                )
            )
            (err ERR_NOT_REGISTERED)
        )
    )
)

;; ---------------------------
;; Claim Daily Rewards
;; ---------------------------
(define-public (claim-reward)
    (match (map-get? nodes tx-sender)
        node
        (if (and (get active node)
                 (>= (- burn-block-height (get last-claim node)) REWARD_INTERVAL)
                 (>= (- burn-block-height (get last-online node)) u0)) ;; online within last day
            (begin
                (map-set nodes tx-sender {
                    staked: (get staked node),
                    last-claim: burn-block-height,
                    active: true,
                    last-online: (get last-online node),
                    cooldown-start: (get cooldown-start node)
                })
                (match (stx-transfer? REWARD_AMOUNT (as-contract tx-sender) tx-sender)
                    success (ok true)
                    error (err ERR_NOT_ELIGIBLE)
                )
            )
            (err ERR_NOT_ELIGIBLE)
        )
        (err ERR_NOT_REGISTERED)
    )
)

;; ---------------------------
;; Pause Node (No Unstaking)
;; ---------------------------
(define-public (pause-node)
    (match (map-get? nodes tx-sender)
        node
        (begin
            (map-set nodes tx-sender {
                staked: (get staked node),
                last-claim: (get last-claim node),
                active: false,
                last-online: (get last-online node),
                cooldown-start: (some burn-block-height)
            })
            (ok true)
        )
        (err ERR_NOT_REGISTERED)
    )
)

;; ---------------------------
;; Unstake after cooldown
;; ---------------------------
(define-public (unstake)
    (match (map-get? nodes tx-sender)
        node
        (match (get cooldown-start node)
            cooldown-val
            (if (>= (- burn-block-height cooldown-val) COOLDOWN_BLOCKS)
                (let ((amount (get staked node)))
                    (begin
                        (map-delete nodes tx-sender)
                        (var-set total-staked (- (var-get total-staked) amount))
                        (match (as-contract (stx-transfer? amount tx-sender tx-sender))
                            success (ok true)
                            error (err ERR_INSUFFICIENT_STAKE)
                        )
                    )
                )
                (err ERR_TOO_SOON)
            )
            (err ERR_NOT_ACTIVE)
        )
        (err ERR_NOT_REGISTERED)
    )
)

;; ---------------------------
;; Oracle Admin: Mark Node Online
;; ---------------------------
(define-public (mark-online (node principal))
    (if (is-eq tx-sender oracle-admin)
        (match (map-get? nodes node)
            n
            (begin
                (map-set nodes node {
                    staked: (get staked n),
                    last-claim: (get last-claim n),
                    active: (get active n),
                    last-online: burn-block-height,
                    cooldown-start: (get cooldown-start n)
                })
                (ok true)
            )
            (err ERR_NOT_REGISTERED)
        )
        (err ERR_UNAUTHORIZED)
    )
)

;; ---------------------------
;; Read-only views
;; ---------------------------
(define-read-only (get-node (who principal))
    (match (map-get? nodes who)
        n (ok n)
        (err ERR_NOT_REGISTERED)
    )
)

(define-read-only (get-total-staked)
    (ok {total: (var-get total-staked)})
)
