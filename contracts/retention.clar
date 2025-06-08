;; Retention Contract
;; Manages required preservation periods

(define-map retention-policies
  { case-type: (string-utf8 50) }
  { retention-period: uint }
)

(define-map case-retention
  { case-id: uint }
  {
    retention-end-height: uint,
    is-preserved: bool
  }
)

(define-data-var contract-owner principal tx-sender)

(define-public (set-retention-policy (case-type (string-utf8 50)) (retention-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (map-set retention-policies
      { case-type: case-type }
      { retention-period: retention-period }
    )
    (ok true)
  )
)

(define-public (set-case-retention (case-id uint) (case-type (string-utf8 50)))
  (let
    (
      (policy (default-to { retention-period: u0 } (map-get? retention-policies { case-type: case-type })))
      (retention-period (get retention-period policy))
      (retention-end-height (+ block-height retention-period))
    )
    (map-set case-retention
      { case-id: case-id }
      {
        retention-end-height: retention-end-height,
        is-preserved: true
      }
    )
    (ok retention-end-height)
  )
)

(define-public (extend-retention (case-id uint) (additional-blocks uint))
  (let
    (
      (current-retention (default-to { retention-end-height: u0, is-preserved: false }
                          (map-get? case-retention { case-id: case-id })))
      (new-end-height (+ (get retention-end-height current-retention) additional-blocks))
    )
    (map-set case-retention
      { case-id: case-id }
      {
        retention-end-height: new-end-height,
        is-preserved: true
      }
    )
    (ok new-end-height)
  )
)

(define-read-only (get-retention-status (case-id uint))
  (let
    (
      (retention-data (default-to { retention-end-height: u0, is-preserved: false }
                      (map-get? case-retention { case-id: case-id })))
    )
    {
      is-preserved: (get is-preserved retention-data),
      blocks-remaining: (if (> (get retention-end-height retention-data) block-height)
                          (- (get retention-end-height retention-data) block-height)
                          u0),
      retention-end-height: (get retention-end-height retention-data)
    }
  )
)

(define-public (mark-for-deletion (case-id uint))
  (let
    (
      (retention-data (default-to { retention-end-height: u0, is-preserved: false }
                      (map-get? case-retention { case-id: case-id })))
    )
    ;; Can only mark for deletion if retention period has passed
    (asserts! (<= (get retention-end-height retention-data) block-height) (err u3))
    (map-set case-retention
      { case-id: case-id }
      {
        retention-end-height: (get retention-end-height retention-data),
        is-preserved: false
      }
    )
    (ok true)
  )
)
