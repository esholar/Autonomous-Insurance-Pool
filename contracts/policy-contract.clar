;; Policy Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))

;; Define policy statuses
(define-constant POLICY_STATUS_ACTIVE u1)
(define-constant POLICY_STATUS_EXPIRED u2)
(define-constant POLICY_STATUS_CLAIMED u3)

;; Data Maps
(define-map policies
  { policy-id: uint }
  {
    policyholder: principal,
    risk-id: uint,
    coverage-amount: uint,
    premium: uint,
    start-block: uint,
    end-block: uint,
    status: uint
  }
)

(define-map claims
  { claim-id: uint }
  {
    policy-id: uint,
    amount: uint,
    status: (string-ascii 20)
  }
)

(define-data-var policy-nonce uint u0)
(define-data-var claim-nonce uint u0)

;; Functions
(define-public (create-policy (risk-id uint) (coverage-amount uint) (duration uint))
  (let
    ((new-policy-id (+ (var-get policy-nonce) u1))
     (premium (unwrap! (contract-call? .risk-assessment-contract calculate-premium risk-id coverage-amount) ERR_NOT_FOUND)))
    (try! (stx-transfer? premium tx-sender (as-contract tx-sender)))
    (map-set policies
      { policy-id: new-policy-id }
      {
        policyholder: tx-sender,
        risk-id: risk-id,
        coverage-amount: coverage-amount,
        premium: premium,
        start-block: block-height,
        end-block: (+ block-height duration),
        status: POLICY_STATUS_ACTIVE
      }
    )
    (var-set policy-nonce new-policy-id)
    (ok new-policy-id)
  )
)

(define-public (file-claim (policy-id uint) (amount uint))
  (let
    ((policy (unwrap! (map-get? policies { policy-id: policy-id }) ERR_NOT_FOUND))
     (new-claim-id (+ (var-get claim-nonce) u1)))
    (asserts! (is-eq (get policyholder policy) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status policy) POLICY_STATUS_ACTIVE) (err u403))
    (asserts! (<= amount (get coverage-amount policy)) ERR_INSUFFICIENT_FUNDS)
    (map-set claims
      { claim-id: new-claim-id }
      {
        policy-id: policy-id,
        amount: amount,
        status: "PENDING"
      }
    )
    (var-set claim-nonce new-claim-id)
    (ok new-claim-id)
  )
)

(define-public (process-claim (claim-id uint) (approve bool))
  (let
    ((claim (unwrap! (map-get? claims { claim-id: claim-id }) ERR_NOT_FOUND))
     (policy (unwrap! (map-get? policies { policy-id: (get policy-id claim) }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (if approve
      (begin
        (try! (as-contract (stx-transfer? (get amount claim) tx-sender (get policyholder policy))))
        (map-set policies
          { policy-id: (get policy-id claim) }
          (merge policy { status: POLICY_STATUS_CLAIMED })
        )
        (map-set claims
          { claim-id: claim-id }
          (merge claim { status: "APPROVED" })
        )
      )
      (map-set claims
        { claim-id: claim-id }
        (merge claim { status: "REJECTED" })
      )
    )
    (ok true)
  )
)

(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

(define-read-only (get-claim (claim-id uint))
  (map-get? claims { claim-id: claim-id })
)

