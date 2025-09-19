;; Decentralized Port Management Smart Contract
;; This contract manages port operations including berth allocation, cargo tracking, and vessel management

;; Error constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-BERTH-NOT-FOUND (err u101))
(define-constant ERR-BERTH-ALREADY-OCCUPIED (err u102))
(define-constant ERR-BERTH-NOT-OCCUPIED (err u103))
(define-constant ERR-INVALID-VESSEL-ID (err u104))
(define-constant ERR-VESSEL-ALREADY-EXISTS (err u105))
(define-constant ERR-VESSEL-NOT-FOUND (err u106))
(define-constant ERR-CARGO-NOT-FOUND (err u107))
(define-constant ERR-CARGO-ALREADY-EXISTS (err u108))
(define-constant ERR-INVALID-CARGO-STATUS (err u109))
(define-constant ERR-BERTH-ALREADY-EXISTS (err u110))
(define-constant ERR-INSUFFICIENT-BERTH-CAPACITY (err u111))
(define-constant ERR-INVALID-TIME-SLOT (err u112))
(define-constant ERR-BOOKING-NOT-FOUND (err u113))
(define-constant ERR-BOOKING-ALREADY-EXISTS (err u114))
(define-constant ERR-INVALID-BOOKING-STATUS (err u115))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-BERTH-CAPACITY u10000)
(define-constant MIN-BOOKING-DURATION u1)
(define-constant MAX-BOOKING-DURATION u168) ;; 7 days in hours

;; Status constants for various entities
(define-constant BERTH-STATUS-AVAILABLE u1)
(define-constant BERTH-STATUS-OCCUPIED u2)
(define-constant BERTH-STATUS-MAINTENANCE u3)

(define-constant VESSEL-STATUS-DOCKED u1)
(define-constant VESSEL-STATUS-ANCHORED u2)
(define-constant VESSEL-STATUS-DEPARTED u3)

(define-constant CARGO-STATUS-PENDING u1)
(define-constant CARGO-STATUS-LOADING u2)
(define-constant CARGO-STATUS-LOADED u3)
(define-constant CARGO-STATUS-UNLOADING u4)
(define-constant CARGO-STATUS-UNLOADED u5)
(define-constant CARGO-STATUS-CLEARED u6)

(define-constant BOOKING-STATUS-PENDING u1)
(define-constant BOOKING-STATUS-CONFIRMED u2)
(define-constant BOOKING-STATUS-ACTIVE u3)
(define-constant BOOKING-STATUS-COMPLETED u4)
(define-constant BOOKING-STATUS-CANCELLED u5)

;; Data maps for storing port entities
;; Berth information with comprehensive details
(define-map berths
  { berth-id: uint }
  {
    name: (string-ascii 50),
    capacity: uint,
    status: uint,
    vessel-id: (optional uint),
    dock-fee-per-hour: uint,
    berth-type: (string-ascii 20),
    depth: uint,
    length: uint,
    width: uint,
    created-at: uint,
    last-updated: uint
  }
)

;; Vessel information with tracking capabilities
(define-map vessels
  { vessel-id: uint }
  {
    name: (string-ascii 100),
    imo-number: (string-ascii 20),
    owner: principal,
    vessel-type: (string-ascii 30),
    length: uint,
    beam: uint,
    draft: uint,
    gross-tonnage: uint,
    status: uint,
    current-berth: (optional uint),
    arrival-time: (optional uint),
    departure-time: (optional uint),
    created-at: uint,
    last-updated: uint
  }
)

;; Cargo tracking with detailed information
(define-map cargo
  { cargo-id: uint }
  {
    description: (string-ascii 200),
    weight: uint,
    volume: uint,
    cargo-type: (string-ascii 50),
    shipper: principal,
    consignee: principal,
    vessel-id: uint,
    status: uint,
    berth-id: (optional uint),
    customs-cleared: bool,
    insurance-value: uint,
    handling-instructions: (string-ascii 300),
    created-at: uint,
    last-updated: uint
  }
)

;; Berth booking system for advance reservations
(define-map berth-bookings
  { booking-id: uint }
  {
    berth-id: uint,
    vessel-id: uint,
    booker: principal,
    start-time: uint,
    end-time: uint,
    total-fee: uint,
    status: uint,
    special-requirements: (string-ascii 200),
    created-at: uint,
    last-updated: uint
  }
)

;; Port authority permissions for role-based access control
(define-map port-authorities
  { authority: principal }
  {
    role: (string-ascii 50),
    permissions: uint,
    active: bool,
    assigned-at: uint
  }
)

;; Operational logs for audit trail
(define-map operation-logs
  { log-id: uint }
  {
    operation-type: (string-ascii 50),
    entity-id: uint,
    entity-type: (string-ascii 20),
    operator: principal,
    details: (string-ascii 500),
    timestamp: uint
  }
)

;; Data variables for tracking counters and state
(define-data-var next-berth-id uint u1)
(define-data-var next-vessel-id uint u1)
(define-data-var next-cargo-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var next-log-id uint u1)
(define-data-var total-berths uint u0)
(define-data-var total-vessels uint u0)
(define-data-var total-cargo uint u0)
(define-data-var port-operational bool true)

;; Authorization functions for access control
;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

;; Check if caller is authorized port authority
(define-private (is-port-authority)
  (match (map-get? port-authorities { authority: tx-sender })
    authority (get active authority)
    false
  )
)

;; Check if caller has admin privileges
(define-private (is-admin)
  (or (is-contract-owner) (is-port-authority))
)

;; Validation functions for data integrity
;; Validate berth status values
(define-private (is-valid-berth-status (status uint))
  (or (is-eq status BERTH-STATUS-AVAILABLE)
      (is-eq status BERTH-STATUS-OCCUPIED)
      (is-eq status BERTH-STATUS-MAINTENANCE))
)

;; Validate vessel status values
(define-private (is-valid-vessel-status (status uint))
  (or (is-eq status VESSEL-STATUS-DOCKED)
      (is-eq status VESSEL-STATUS-ANCHORED)
      (is-eq status VESSEL-STATUS-DEPARTED))
)

;; Validate cargo status values
(define-private (is-valid-cargo-status (status uint))
  (or (is-eq status CARGO-STATUS-PENDING)
      (is-eq status CARGO-STATUS-LOADING)
      (is-eq status CARGO-STATUS-LOADED)
      (is-eq status CARGO-STATUS-UNLOADING)
      (is-eq status CARGO-STATUS-UNLOADED)
      (is-eq status CARGO-STATUS-CLEARED))
)

;; Validate booking status values
(define-private (is-valid-booking-status (status uint))
  (or (is-eq status BOOKING-STATUS-PENDING)
      (is-eq status BOOKING-STATUS-CONFIRMED)
      (is-eq status BOOKING-STATUS-ACTIVE)
      (is-eq status BOOKING-STATUS-COMPLETED)
      (is-eq status BOOKING-STATUS-CANCELLED))
)

;; Validate booking duration is within limits
(define-private (is-valid-booking-duration (start-time uint) (end-time uint))
  (let ((duration (- end-time start-time)))
    (and (>= duration MIN-BOOKING-DURATION)
         (<= duration MAX-BOOKING-DURATION)
         (> end-time start-time)))
)

;; Utility functions for common operations
;; Get current block time for timestamps
(define-private (get-current-time)
  block-height
)

;; Log operation for audit trail
(define-private (log-operation (operation-type (string-ascii 50)) (entity-id uint) (entity-type (string-ascii 20)) (details (string-ascii 500)))
  (let ((log-id (var-get next-log-id)))
    (map-set operation-logs
      { log-id: log-id }
      {
        operation-type: operation-type,
        entity-id: entity-id,
        entity-type: entity-type,
        operator: tx-sender,
        details: details,
        timestamp: (get-current-time)
      }
    )
    (var-set next-log-id (+ log-id u1))
    (ok log-id))
)

;; Berth management functions
;; Create a new berth with comprehensive information
(define-public (create-berth (name (string-ascii 50)) (capacity uint) (dock-fee-per-hour uint) 
                           (berth-type (string-ascii 20)) (depth uint) (length uint) (width uint))
  (let ((berth-id (var-get next-berth-id)))
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= capacity MAX-BERTH-CAPACITY) ERR-INSUFFICIENT-BERTH-CAPACITY)
    (asserts! (is-none (map-get? berths { berth-id: berth-id })) ERR-BERTH-ALREADY-EXISTS)
    
    (map-set berths
      { berth-id: berth-id }
      {
        name: name,
        capacity: capacity,
        status: BERTH-STATUS-AVAILABLE,
        vessel-id: none,
        dock-fee-per-hour: dock-fee-per-hour,
        berth-type: berth-type,
        depth: depth,
        length: length,
        width: width,
        created-at: (get-current-time),
        last-updated: (get-current-time)
      }
    )
    
    (var-set next-berth-id (+ berth-id u1))
    (var-set total-berths (+ (var-get total-berths) u1))
    
    (unwrap-panic (log-operation "CREATE_BERTH" berth-id "BERTH" "New berth created"))
    (ok berth-id))
)

;; Update berth status with proper validation
(define-public (update-berth-status (berth-id uint) (new-status uint))
  (let ((berth-data (unwrap! (map-get? berths { berth-id: berth-id }) ERR-BERTH-NOT-FOUND)))
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-berth-status new-status) ERR-INVALID-CARGO-STATUS)
    
    (map-set berths
      { berth-id: berth-id }
      (merge berth-data { status: new-status, last-updated: (get-current-time) })
    )
    
    (unwrap-panic (log-operation "UPDATE_BERTH_STATUS" berth-id "BERTH" "Berth status updated"))
    (ok true))
)

;; Allocate berth to vessel with comprehensive checks
(define-public (allocate-berth (berth-id uint) (vessel-id uint))
  (let ((berth-data (unwrap! (map-get? berths { berth-id: berth-id }) ERR-BERTH-NOT-FOUND))
        (vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND)))
    
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get status berth-data) BERTH-STATUS-AVAILABLE) ERR-BERTH-ALREADY-OCCUPIED)
    (asserts! (is-none (get current-berth vessel-data)) ERR-BERTH-ALREADY-OCCUPIED)
    
    ;; Update berth with vessel information
    (map-set berths
      { berth-id: berth-id }
      (merge berth-data {
        status: BERTH-STATUS-OCCUPIED,
        vessel-id: (some vessel-id),
        last-updated: (get-current-time)
      })
    )
    
    ;; Update vessel with berth information
    (map-set vessels
      { vessel-id: vessel-id }
      (merge vessel-data {
        status: VESSEL-STATUS-DOCKED,
        current-berth: (some berth-id),
        arrival-time: (some (get-current-time)),
        last-updated: (get-current-time)
      })
    )
    
    (unwrap-panic (log-operation "ALLOCATE_BERTH" berth-id "BERTH" "Berth allocated to vessel"))
    (ok true))
)

;; Deallocate berth from vessel
(define-public (deallocate-berth (berth-id uint))
  (let ((berth-data (unwrap! (map-get? berths { berth-id: berth-id }) ERR-BERTH-NOT-FOUND))
        (vessel-id (unwrap! (get vessel-id berth-data) ERR-BERTH-NOT-OCCUPIED)))
    
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get status berth-data) BERTH-STATUS-OCCUPIED) ERR-BERTH-NOT-OCCUPIED)
    
    (let ((vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND)))
      ;; Update berth status to available
      (map-set berths
        { berth-id: berth-id }
        (merge berth-data {
          status: BERTH-STATUS-AVAILABLE,
          vessel-id: none,
          last-updated: (get-current-time)
        })
      )
      
      ;; Update vessel status to departed
      (map-set vessels
        { vessel-id: vessel-id }
        (merge vessel-data {
          status: VESSEL-STATUS-DEPARTED,
          current-berth: none,
          departure-time: (some (get-current-time)),
          last-updated: (get-current-time)
        })
      )
      
      (unwrap-panic (log-operation "DEALLOCATE_BERTH" berth-id "BERTH" "Berth deallocated from vessel"))
      (ok true)))
)

;; Vessel management functions
;; Register a new vessel with comprehensive details
(define-public (register-vessel (name (string-ascii 100)) (imo-number (string-ascii 20)) (vessel-type (string-ascii 30))
                               (length uint) (beam uint) (draft uint) (gross-tonnage uint))
  (let ((vessel-id (var-get next-vessel-id)))
    (asserts! (is-none (map-get? vessels { vessel-id: vessel-id })) ERR-VESSEL-ALREADY-EXISTS)
    
    (map-set vessels
      { vessel-id: vessel-id }
      {
        name: name,
        imo-number: imo-number,
        owner: tx-sender,
        vessel-type: vessel-type,
        length: length,
        beam: beam,
        draft: draft,
        gross-tonnage: gross-tonnage,
        status: VESSEL-STATUS-ANCHORED,
        current-berth: none,
        arrival-time: none,
        departure-time: none,
        created-at: (get-current-time),
        last-updated: (get-current-time)
      }
    )
    
    (var-set next-vessel-id (+ vessel-id u1))
    (var-set total-vessels (+ (var-get total-vessels) u1))
    
    (unwrap-panic (log-operation "REGISTER_VESSEL" vessel-id "VESSEL" "New vessel registered"))
    (ok vessel-id))
)

;; Update vessel status with validation
(define-public (update-vessel-status (vessel-id uint) (new-status uint))
  (let ((vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get owner vessel-data)) (is-admin)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-vessel-status new-status) ERR-INVALID-CARGO-STATUS)
    
    (map-set vessels
      { vessel-id: vessel-id }
      (merge vessel-data { status: new-status, last-updated: (get-current-time) })
    )
    
    (unwrap-panic (log-operation "UPDATE_VESSEL_STATUS" vessel-id "VESSEL" "Vessel status updated"))
    (ok true))
)

;; Cargo management functions
;; Create cargo entry with comprehensive tracking
(define-public (create-cargo (description (string-ascii 200)) (weight uint) (volume uint) (cargo-type (string-ascii 50))
                           (consignee principal) (vessel-id uint) (insurance-value uint) 
                           (handling-instructions (string-ascii 300)))
  (let ((cargo-id (var-get next-cargo-id)))
    (asserts! (is-some (map-get? vessels { vessel-id: vessel-id })) ERR-VESSEL-NOT-FOUND)
    (asserts! (is-none (map-get? cargo { cargo-id: cargo-id })) ERR-CARGO-ALREADY-EXISTS)
    
    (map-set cargo
      { cargo-id: cargo-id }
      {
        description: description,
        weight: weight,
        volume: volume,
        cargo-type: cargo-type,
        shipper: tx-sender,
        consignee: consignee,
        vessel-id: vessel-id,
        status: CARGO-STATUS-PENDING,
        berth-id: none,
        customs-cleared: false,
        insurance-value: insurance-value,
        handling-instructions: handling-instructions,
        created-at: (get-current-time),
        last-updated: (get-current-time)
      }
    )
    
    (var-set next-cargo-id (+ cargo-id u1))
    (var-set total-cargo (+ (var-get total-cargo) u1))
    
    (unwrap-panic (log-operation "CREATE_CARGO" cargo-id "CARGO" "New cargo entry created"))
    (ok cargo-id))
)

;; Update cargo status with proper authorization
(define-public (update-cargo-status (cargo-id uint) (new-status uint))
  (let ((cargo-data (unwrap! (map-get? cargo { cargo-id: cargo-id }) ERR-CARGO-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get shipper cargo-data)) 
                  (is-eq tx-sender (get consignee cargo-data)) 
                  (is-admin)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-cargo-status new-status) ERR-INVALID-CARGO-STATUS)
    
    (map-set cargo
      { cargo-id: cargo-id }
      (merge cargo-data { status: new-status, last-updated: (get-current-time) })
    )
    
    (unwrap-panic (log-operation "UPDATE_CARGO_STATUS" cargo-id "CARGO" "Cargo status updated"))
    (ok true))
)

;; Clear cargo through customs
(define-public (clear-cargo-customs (cargo-id uint))
  (let ((cargo-data (unwrap! (map-get? cargo { cargo-id: cargo-id }) ERR-CARGO-NOT-FOUND)))
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set cargo
      { cargo-id: cargo-id }
      (merge cargo-data { customs-cleared: true, last-updated: (get-current-time) })
    )
    
    (unwrap-panic (log-operation "CLEAR_CUSTOMS" cargo-id "CARGO" "Cargo cleared through customs"))
    (ok true))
)

;; Berth booking functions
;; Create berth booking with validation
(define-public (create-berth-booking (berth-id uint) (vessel-id uint) (start-time uint) 
                                    (end-time uint) (special-requirements (string-ascii 200)))
  (let ((booking-id (var-get next-booking-id))
        (berth-data (unwrap! (map-get? berths { berth-id: berth-id }) ERR-BERTH-NOT-FOUND))
        (vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND)))
    
    (asserts! (is-valid-booking-duration start-time end-time) ERR-INVALID-TIME-SLOT)
    (asserts! (is-none (map-get? berth-bookings { booking-id: booking-id })) ERR-BOOKING-ALREADY-EXISTS)
    
    (let ((duration (- end-time start-time))
          (total-fee (* duration (get dock-fee-per-hour berth-data))))
      
      (map-set berth-bookings
        { booking-id: booking-id }
        {
          berth-id: berth-id,
          vessel-id: vessel-id,
          booker: tx-sender,
          start-time: start-time,
          end-time: end-time,
          total-fee: total-fee,
          status: BOOKING-STATUS-PENDING,
          special-requirements: special-requirements,
          created-at: (get-current-time),
          last-updated: (get-current-time)
        }
      )
      
      (var-set next-booking-id (+ booking-id u1))
      
      (unwrap-panic (log-operation "CREATE_BOOKING" booking-id "BOOKING" "New berth booking created"))
      (ok booking-id)))
)

;; Update booking status
(define-public (update-booking-status (booking-id uint) (new-status uint))
  (let ((booking-data (unwrap! (map-get? berth-bookings { booking-id: booking-id }) ERR-BOOKING-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get booker booking-data)) (is-admin)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-booking-status new-status) ERR-INVALID-BOOKING-STATUS)
    
    (map-set berth-bookings
      { booking-id: booking-id }
      (merge booking-data { status: new-status, last-updated: (get-current-time) })
    )
    
    (unwrap-panic (log-operation "UPDATE_BOOKING_STATUS" booking-id "BOOKING" "Booking status updated"))
    (ok true))
)

;; Port authority management functions
;; Add port authority with role-based permissions
(define-public (add-port-authority (authority principal) (role (string-ascii 50)) (permissions uint))
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set port-authorities
      { authority: authority }
      {
        role: role,
        permissions: permissions,
        active: true,
        assigned-at: (get-current-time)
      }
    )
    
    (unwrap-panic (log-operation "ADD_AUTHORITY" u0 "AUTHORITY" "New port authority added"))
    (ok true))
)

;; Remove port authority
(define-public (remove-port-authority (authority principal))
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    
    (map-delete port-authorities { authority: authority })
    
    (unwrap-panic (log-operation "REMOVE_AUTHORITY" u0 "AUTHORITY" "Port authority removed"))
    (ok true))
)

;; Read-only functions for data retrieval
;; Get berth information
(define-read-only (get-berth (berth-id uint))
  (map-get? berths { berth-id: berth-id })
)

;; Get vessel information
(define-read-only (get-vessel (vessel-id uint))
  (map-get? vessels { vessel-id: vessel-id })
)

;; Get cargo information
(define-read-only (get-cargo (cargo-id uint))
  (map-get? cargo { cargo-id: cargo-id })
)

;; Get booking information
(define-read-only (get-booking (booking-id uint))
  (map-get? berth-bookings { booking-id: booking-id })
)

;; Get operation log
(define-read-only (get-operation-log (log-id uint))
  (map-get? operation-logs { log-id: log-id })
)

;; Get port statistics
(define-read-only (get-port-stats)
  {
    total-berths: (var-get total-berths),
    total-vessels: (var-get total-vessels),
    total-cargo: (var-get total-cargo),
    port-operational: (var-get port-operational),
    next-berth-id: (var-get next-berth-id),
    next-vessel-id: (var-get next-vessel-id),
    next-cargo-id: (var-get next-cargo-id),
    next-booking-id: (var-get next-booking-id)
  }
)

;; Check if berth is available
(define-read-only (is-berth-available (berth-id uint))
  (match (map-get? berths { berth-id: berth-id })
    berth (is-eq (get status berth) BERTH-STATUS-AVAILABLE)
    false
  )
)

;; Get all cargo for a vessel
(define-read-only (get-vessel-cargo-count (vessel-id uint))
  (var-get total-cargo)
)

;; Emergency functions for contract management
;; Set port operational status
(define-public (set-port-operational (operational bool))
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set port-operational operational)
    (unwrap-panic (log-operation "SET_OPERATIONAL" u0 "PORT" "Port operational status changed"))
    (ok true))
)