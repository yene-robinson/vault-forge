;; VaultForge Protocol
;; 
;; Revolutionary decentralized lending infrastructure powering the next generation of DeFi
;; 
;; VaultForge represents a cutting-edge multi-asset collateral system designed to democratize 
;; access to decentralized lending. Built on the robust Stacks blockchain, this protocol 
;; enables users to unlock liquidity from their digital assets through sophisticated 
;; collateral management and risk assessment mechanisms.
;;
;; The protocol features an intelligent liquidation engine that maintains system stability 
;; through automated risk management, while providing users with maximum flexibility in 
;; managing their collateral positions. With support for both STX and xBTC as collateral 
;; assets, VaultForge creates a bridge between Bitcoin's security and DeFi's innovation.

;; CONSTANTS AND SYSTEM PARAMETERS

(define-constant CONTRACT-OWNER tx-sender)

;; Error Management System
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-VAULT-NOT-FOUND (err u1001))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1002))
(define-constant ERR-VAULT-UNDERCOLLATERALIZED (err u1003))
(define-constant ERR-LIQUIDATION-NOT-ALLOWED (err u1004))
(define-constant ERR-INVALID-AMOUNT (err u1005))
(define-constant ERR-ORACLE-PRICE-STALE (err u1006))
(define-constant ERR-MINIMUM-COLLATERAL-RATIO (err u1007))
(define-constant ERR-VAULT-ALREADY-EXISTS (err u1008))
(define-constant ERR-INSUFFICIENT-USDX-BALANCE (err u1009))
(define-constant ERR-TRANSFER-FAILED (err u1010))

;; Risk Management Parameters
(define-constant LIQUIDATION-RATIO u150)           ;; 150% - liquidation threshold
(define-constant MINIMUM-COLLATERAL-RATIO u200)    ;; 200% - minimum for new vaults
(define-constant LIQUIDATION-PENALTY u110)         ;; 10% liquidation penalty
(define-constant STABILITY-FEE-RATE u2)            ;; 2% annual stability fee
(define-constant MAX-PRICE-AGE u3600)              ;; 1 hour max price age (in seconds)

;; DATA STRUCTURES AND STORAGE

;; Vault Management System
(define-map vaults
    { vault-id: uint }
    {
        owner: principal,
        stx-collateral: uint,
        xbtc-collateral: uint,
        debt: uint,
        last-update: uint,
        is-active: bool,
    }
)

;; User Vault Registry
(define-map user-vaults
    { user: principal }
    { vault-ids: (list 10 uint) }
)

;; Oracle Price Feed System
(define-map price-feeds
    { asset: (string-ascii 10) }
    {
        price: uint,
        timestamp: uint,
        confidence: uint,
    }
)

;; Protocol State Variables
(define-data-var total-vaults uint u0)
(define-data-var total-debt uint u0)
(define-data-var total-stx-collateral uint u0)
(define-data-var total-xbtc-collateral uint u0)
(define-data-var liquidation-pool uint u0)

;; Access Control Systems
(define-map authorized-liquidators principal bool)
(define-map oracle-operators principal bool)

;; USDX SYNTHETIC ASSET (SIP-010 COMPLIANT)

(define-fungible-token usdx)

;; Token Metadata
(define-data-var token-name (string-ascii 32) "USDx Synthetic Dollar")
(define-data-var token-symbol (string-ascii 10) "USDx")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var token-decimals uint u6)

;; SIP-010 Standard Implementation
(define-read-only (get-name)
    (ok (var-get token-name))
)

(define-read-only (get-symbol)
    (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
    (ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance usdx who))
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply usdx))
)

(define-read-only (get-token-uri)
    (ok (var-get token-uri))
)

(define-public (transfer
        (amount uint)
        (from principal)
        (to principal)
        (memo (optional (buff 34)))
    )
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller))
            ERR-NOT-AUTHORIZED
        )
        (asserts! (not (is-eq from to)) ERR-INVALID-AMOUNT)
        (ft-transfer? usdx amount from to)
    )
)

;; ORACLE PRICE FEED MANAGEMENT

(define-public (set-oracle-operator
        (operator principal)
        (authorized bool)
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq operator tx-sender)) ERR-INVALID-AMOUNT)
        (ok (map-set oracle-operators operator authorized))
    )
)

(define-public (update-price
        (asset (string-ascii 10))
        (price uint)
        (confidence uint)
    )
    (begin
        (asserts! (default-to false (map-get? oracle-operators tx-sender))
            ERR-NOT-AUTHORIZED
        )
        (asserts! (> price u0) ERR-INVALID-AMOUNT)
        (asserts! (and (>= confidence u1) (<= confidence u100))
            ERR-INVALID-AMOUNT
        )
        (asserts! (> (len asset) u0) ERR-INVALID-AMOUNT)
        (ok (map-set price-feeds { asset: asset } {
            price: price,
            timestamp: stacks-block-height,
            confidence: confidence,
        }))
    )
)

(define-read-only (get-price (asset (string-ascii 10)))
    (let ((price-data (map-get? price-feeds { asset: asset })))
        (match price-data
            feed (if (< (- stacks-block-height (get timestamp feed)) MAX-PRICE-AGE)
                (ok (get price feed))
                ERR-ORACLE-PRICE-STALE
            )
            ERR-ORACLE-PRICE-STALE
        )
    )
)

;; VAULT LIFECYCLE MANAGEMENT

(define-public (create-vault
        (stx-amount uint)
        (xbtc-amount uint)
    )
    (let (
            (vault-id (+ (var-get total-vaults) u1))
            (stx-price (unwrap! (get-price "STX") ERR-ORACLE-PRICE-STALE))
            (xbtc-price (unwrap! (get-price "xBTC") ERR-ORACLE-PRICE-STALE))
            (total-collateral-value (+ (* stx-amount stx-price) (* xbtc-amount xbtc-price)))
            (user-vaults-list (default-to (list)
                (get vault-ids (map-get? user-vaults { user: tx-sender }))
            ))
        )
        (asserts! (> stx-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= xbtc-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (< vault-id u1000000) ERR-INVALID-AMOUNT)
        (asserts! (is-none (map-get? vaults { vault-id: vault-id }))
            ERR-VAULT-ALREADY-EXISTS
        )
        
        ;; Transfer collateral to contract
        (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender)))
        
        ;; Create vault record
        (map-set vaults { vault-id: vault-id } {
            owner: tx-sender,
            stx-collateral: stx-amount,
            xbtc-collateral: xbtc-amount,
            debt: u0,
            last-update: stacks-block-height,
            is-active: true,
        })
        
        ;; Update user vault registry
        (map-set user-vaults { user: tx-sender } { 
            vault-ids: (unwrap! (as-max-len? (append user-vaults-list vault-id) u10)
                ERR-INVALID-AMOUNT
            ) 
        })
        
        ;; Update protocol statistics
        (var-set total-vaults vault-id)
        (var-set total-stx-collateral
            (+ (var-get total-stx-collateral) stx-amount)
        )
        (var-set total-xbtc-collateral
            (+ (var-get total-xbtc-collateral) xbtc-amount)
        )
        
        (ok vault-id)
    )
)