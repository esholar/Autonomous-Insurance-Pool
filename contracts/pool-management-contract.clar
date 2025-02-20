;; Pool Management Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))

;; Data Variables
(define-data-var total-pool-funds uint u0)
(define-data-var reserve-ratio uint u2000) ;; 20% reserve ratio (out of 10000)

;; Functions
(define-public (deposit-funds (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-pool-funds (+ (var-get total-pool-funds) amount))
    (ok true)
  )
)

(define-public (withdraw-funds (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= amount (get-withdrawable-funds)) ERR_INSUFFICIENT_FUNDS)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT_OWNER)))
    (var-set total-pool-funds (- (var-get total-pool-funds) amount))
    (ok true)
  )
)

(define-read-only (get-total-pool-funds)
  (ok (var-get total-pool-funds))
)

(define-read-only (get-reserve-amount)
  (ok (/ (* (var-get total-pool-funds) (var-get reserve-ratio)) u10000))
)

(define-read-only (get-withdrawable-funds)
  (ok (- (var-get total-pool-funds) (unwrap! (get-reserve-amount) (err u500))))
)

(define-public (update-reserve-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-ratio u10000) (err u400))
    (var-set reserve-ratio new-ratio)
    (ok true)
  )
)

(define-public (process-premium (amount uint))
  (begin
    (asserts! (is-eq tx-sender (contract-call? .policy-contract get-contract-address)) ERR_NOT_AUTHORIZED)
    (var-set total-pool-funds (+ (var-get total-pool-funds) amount))
    (ok true)
  )
)

(define-public (process-claim-payout (amount uint))
  (begin
    (asserts! (is-eq tx-sender (contract-call? .policy-contract get-contract-address)) ERR_NOT_AUTHORIZED)
    (asserts! (<= amount (get-withdrawable-funds)) ERR_INSUFFICIENT_FUNDS)
    (var-set total-pool-funds (- (var-get total-pool-funds) amount))
    (ok true)
  )
)

