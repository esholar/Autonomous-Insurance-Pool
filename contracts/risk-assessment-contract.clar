;; Risk Assessment Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))

;; Data Maps
(define-map risk-profiles
  { risk-id: uint }
  {
    risk-type: (string-ascii 50),
    base-premium: uint,
    risk-factor: uint
  }
)

(define-data-var risk-nonce uint u0)

;; Functions
(define-public (add-risk-profile (risk-type (string-ascii 50)) (base-premium uint) (risk-factor uint))
  (let
    ((new-risk-id (+ (var-get risk-nonce) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set risk-profiles
      { risk-id: new-risk-id }
      {
        risk-type: risk-type,
        base-premium: base-premium,
        risk-factor: risk-factor
      }
    )
    (var-set risk-nonce new-risk-id)
    (ok new-risk-id)
  )
)

(define-read-only (get-risk-profile (risk-id uint))
  (map-get? risk-profiles { risk-id: risk-id })
)

(define-public (update-risk-profile (risk-id uint) (base-premium uint) (risk-factor uint))
  (let
    ((risk-profile (unwrap! (map-get? risk-profiles { risk-id: risk-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (ok (map-set risk-profiles
      { risk-id: risk-id }
      (merge risk-profile
        {
          base-premium: base-premium,
          risk-factor: risk-factor
        }
      )
    ))
  )
)

(define-read-only (calculate-premium (risk-id uint) (coverage-amount uint))
  (match (map-get? risk-profiles { risk-id: risk-id })
    profile (ok (/ (* (get base-premium profile) coverage-amount (get risk-factor profile)) u10000))
    ERR_NOT_FOUND
  )
)

