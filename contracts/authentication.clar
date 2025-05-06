;; Authentication Contract
;; Validates legitimacy of submitted materials

(define-map verified-documents
  { document-hash: (buff 32) }
  {
    verifier: principal,
    verification-time: uint,
    verification-method: (string-utf8 50),
    is-authentic: bool
  }
)

(define-map authorized-verifiers
  { verifier: principal }
  { is-authorized: bool }
)

(define-data-var contract-owner principal tx-sender)

(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (map-set authorized-verifiers
      { verifier: verifier }
      { is-authorized: true }
    )
    (ok true)
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (map-delete authorized-verifiers { verifier: verifier })
    (ok true)
  )
)

(define-read-only (is-authorized-verifier (verifier principal))
  (default-to { is-authorized: false }
    (map-get? authorized-verifiers { verifier: verifier }))
)

(define-public (verify-document (document-hash (buff 32)) (verification-method (string-utf8 50)) (is-authentic bool))
  (let
    (
      (verifier-status (is-authorized-verifier tx-sender))
    )
    ;; Only authorized verifiers can verify documents
    (asserts! (get is-authorized verifier-status) (err u2))
    (map-set verified-documents
      { document-hash: document-hash }
      {
        verifier: tx-sender,
        verification-time: block-height,
        verification-method: verification-method,
        is-authentic: is-authentic
      }
    )
    (ok true)
  )
)

(define-read-only (check-document-authenticity (document-hash (buff 32)))
  (map-get? verified-documents { document-hash: document-hash })
)
