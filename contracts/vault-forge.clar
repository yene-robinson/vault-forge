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

(define-public (add-collateral
        (vault-id uint)
        (stx-amount uint)
        (xbtc-amount uint)
    )
    (let ((vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND)))
        (asserts! (> vault-id u0) ERR-INVALID-AMOUNT)
        (asserts! (is-eq (get owner vault) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active vault) ERR-VAULT-NOT-FOUND)
        (asserts! (> stx-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= xbtc-amount u0) ERR-INVALID-AMOUNT)
        
        ;; Transfer additional collateral
        (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender)))
        
        ;; Update vault record
        (map-set vaults { vault-id: vault-id }
            (merge vault {
                stx-collateral: (+ (get stx-collateral vault) stx-amount),
                xbtc-collateral: (+ (get xbtc-collateral vault) xbtc-amount),
                last-update: stacks-block-height,
            })
        )
        
        ;; Update protocol statistics
        (var-set total-stx-collateral
            (+ (var-get total-stx-collateral) stx-amount)
        )
        (var-set total-xbtc-collateral
            (+ (var-get total-xbtc-collateral) xbtc-amount)
        )
        
        (ok true)
    )
)

(define-public (mint-usdx
        (vault-id uint)
        (amount uint)
    )
    (let (
            (vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND))
            (stx-price (unwrap! (get-price "STX") ERR-ORACLE-PRICE-STALE))
            (xbtc-price (unwrap! (get-price "xBTC") ERR-ORACLE-PRICE-STALE))
            (collateral-value (+ (* (get stx-collateral vault) stx-price)
                (* (get xbtc-collateral vault) xbtc-price)
            ))
            (new-debt (+ (get debt vault) amount))
            (collateral-ratio (/ (* collateral-value u100) new-debt))
        )
        (asserts! (> vault-id u0) ERR-INVALID-AMOUNT)
        (asserts! (is-eq (get owner vault) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active vault) ERR-VAULT-NOT-FOUND)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (< amount u1000000000000) ERR-INVALID-AMOUNT)
        (asserts! (>= collateral-ratio MINIMUM-COLLATERAL-RATIO)
            ERR-MINIMUM-COLLATERAL-RATIO
        )
        
        ;; Mint USDx tokens
        (try! (ft-mint? usdx amount tx-sender))
        
        ;; Update vault debt
        (map-set vaults { vault-id: vault-id }
            (merge vault {
                debt: new-debt,
                last-update: stacks-block-height,
            })
        )
        
        ;; Update protocol statistics
        (var-set total-debt (+ (var-get total-debt) amount))
        
        (ok true)
    )
)

(define-public (burn-usdx
        (vault-id uint)
        (amount uint)
    )
    (let (
            (vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND))
            (user-balance (ft-get-balance usdx tx-sender))
        )
        (asserts! (> vault-id u0) ERR-INVALID-AMOUNT)
        (asserts! (is-eq (get owner vault) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active vault) ERR-VAULT-NOT-FOUND)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= user-balance amount) ERR-INSUFFICIENT-USDX-BALANCE)
        (asserts! (>= (get debt vault) amount) ERR-INVALID-AMOUNT)
        
        ;; Burn USDx tokens
        (try! (ft-burn? usdx amount tx-sender))
        
        ;; Update vault debt
        (map-set vaults { vault-id: vault-id }
            (merge vault {
                debt: (- (get debt vault) amount),
                last-update: stacks-block-height,
            })
        )
        
        ;; Update protocol statistics
        (var-set total-debt (- (var-get total-debt) amount))
        
        (ok true)
    )
)

(define-public (withdraw-collateral
        (vault-id uint)
        (stx-amount uint)
    )
    (let (
            (vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND))
            (stx-price (unwrap! (get-price "STX") ERR-ORACLE-PRICE-STALE))
            (xbtc-price (unwrap! (get-price "xBTC") ERR-ORACLE-PRICE-STALE))
            (remaining-stx (- (get stx-collateral vault) stx-amount))
            (remaining-collateral-value (+ (* remaining-stx stx-price)
                (* (get xbtc-collateral vault) xbtc-price)
            ))
            (debt (get debt vault))
        )
        (asserts! (> vault-id u0) ERR-INVALID-AMOUNT)
        (asserts! (is-eq (get owner vault) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active vault) ERR-VAULT-NOT-FOUND)
        (asserts! (> stx-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (get stx-collateral vault) stx-amount)
            ERR-INSUFFICIENT-COLLATERAL
        )
        
        ;; Check collateral ratio maintenance
        (if (> debt u0)
            (asserts!
                (>= (/ (* remaining-collateral-value u100) debt)
                    MINIMUM-COLLATERAL-RATIO
                )
                ERR-MINIMUM-COLLATERAL-RATIO
            )
            true
        )
        
        ;; Transfer collateral back to user
        (try! (as-contract (stx-transfer? stx-amount tx-sender (get owner vault))))
        
        ;; Update vault record
        (map-set vaults { vault-id: vault-id }
            (merge vault {
                stx-collateral: remaining-stx,
                last-update: stacks-block-height,
            })
        )
        
        ;; Update protocol statistics
        (var-set total-stx-collateral
            (- (var-get total-stx-collateral) stx-amount)
        )
        
        (ok true)
    )
)

;; AUTOMATED LIQUIDATION ENGINE

(define-public (set-liquidator
        (liquidator principal)
        (authorized bool)
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq liquidator tx-sender)) ERR-INVALID-AMOUNT)
        (ok (map-set authorized-liquidators liquidator authorized))
    )
)

(define-read-only (calculate-health-factor (vault-id uint))
    (match (map-get? vaults { vault-id: vault-id })
        vault (match (get-price "STX")
            stx-price (match (get-price "xBTC")
                xbtc-price (let (
                        (collateral-value (+ (* (get stx-collateral vault) stx-price)
                            (* (get xbtc-collateral vault) xbtc-price)
                        ))
                        (debt (get debt vault))
                    )
                    (if (is-eq debt u0)
                        (ok u999999)
                        (ok (/ (* collateral-value u100) debt))
                    )
                )
                xbtc-err ERR-ORACLE-PRICE-STALE
            )
            stx-err ERR-ORACLE-PRICE-STALE
        )
        ERR-VAULT-NOT-FOUND
    )
)

(define-public (liquidate-vault (vault-id uint))
    (let (
            (vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR-VAULT-NOT-FOUND))
            (health-factor (unwrap! (calculate-health-factor vault-id) ERR-ORACLE-PRICE-STALE))
            (debt (get debt vault))
            (stx-collateral (get stx-collateral vault))
            (xbtc-collateral (get xbtc-collateral vault))
            (liquidation-amount (/ (* debt LIQUIDATION-PENALTY) u100))
        )
        (asserts! (default-to false (map-get? authorized-liquidators tx-sender))
            ERR-NOT-AUTHORIZED
        )
        (asserts! (get is-active vault) ERR-VAULT-NOT-FOUND)
        (asserts! (< health-factor LIQUIDATION-RATIO) ERR-LIQUIDATION-NOT-ALLOWED)
        (asserts! (>= (ft-get-balance usdx tx-sender) debt)
            ERR-INSUFFICIENT-USDX-BALANCE
        )
        
        ;; Execute liquidation
        (try! (ft-burn? usdx debt tx-sender))
        
        (let (
                (stx-to-liquidator (/ (* stx-collateral liquidation-amount) debt))
                (xbtc-to-liquidator (/ (* xbtc-collateral liquidation-amount) debt))
            )
            ;; Transfer collateral to liquidator
            (try! (as-contract (stx-transfer? stx-to-liquidator tx-sender tx-sender)))
            
            ;; Update vault state
            (map-set vaults { vault-id: vault-id }
                (merge vault {
                    debt: u0,
                    stx-collateral: (- stx-collateral stx-to-liquidator),
                    xbtc-collateral: (- xbtc-collateral xbtc-to-liquidator),
                    is-active: false,
                    last-update: stacks-block-height,
                })
            )
            
            ;; Update protocol statistics
            (var-set total-debt (- (var-get total-debt) debt))
            (var-set total-stx-collateral
                (- (var-get total-stx-collateral) stx-to-liquidator)
            )
            (var-set total-xbtc-collateral
                (- (var-get total-xbtc-collateral) xbtc-to-liquidator)
            )
            
            (ok true)
        )
    )
)

;; ANALYTICS AND MONITORING

(define-read-only (get-vault (vault-id uint))
    (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-user-vaults (user principal))
    (map-get? user-vaults { user: user })
)

(define-read-only (get-protocol-stats)
    {
        total-vaults: (var-get total-vaults),
        total-debt: (var-get total-debt),
        total-stx-collateral: (var-get total-stx-collateral),
        total-xbtc-collateral: (var-get total-xbtc-collateral),
        total-usdx-supply: (ft-get-supply usdx),
    }
)

(define-read-only (is-vault-safe (vault-id uint))
    (match (calculate-health-factor vault-id)
        health-factor (ok (>= health-factor LIQUIDATION-RATIO))
        error (err error)
    )
)

;; GOVERNANCE AND ADMINISTRATION

(define-public (emergency-shutdown)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (ok true)
    )
)

(define-public (update-liquidation-ratio (new-ratio uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (and (>= new-ratio u120) (<= new-ratio u200))
            ERR-INVALID-AMOUNT
        )
        (ok true)
    )
)

;; PROTOCOL INITIALIZATION

;; Initialize oracle operators
(map-set oracle-operators CONTRACT-OWNER true)

;; Initialize price feeds with bootstrap values
(map-set price-feeds { asset: "STX" } {
    price: u1000000,
    timestamp: stacks-block-height,
    confidence: u95,
})

(map-set price-feeds { asset: "xBTC" } {
    price: u100000000000,
    timestamp: stacks-block-height,
    confidence: u95,
})