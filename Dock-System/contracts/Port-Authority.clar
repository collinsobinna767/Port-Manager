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
(define-constant ERR-INVALID-INPUT (err u116))
(define-constant ERR-INVALID-DIMENSIONS (err u117))
(define-constant ERR-INVALID-FEE (err u118))
(define-constant ERR-INVALID-WEIGHT (err u119))
(define-constant ERR-INVALID-VOLUME (err u120))
(define-constant ERR-AUTHORITY-ALREADY-EXISTS (err u121))
(define-constant ERR-AUTHORITY-NOT-FOUND (err u122))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-BERTH-CAPACITY u10000)
(define-constant MIN-BOOKING-DURATION u1)
(define-constant MAX-BOOKING-DURATION u168) ;; 7 days in hours
(define-constant MAX-DOCK-FEE u1000000) ;; Maximum fee per hour
(define-constant MAX-DIMENSIONS u50000) ;; Maximum dimension in meters
(define-constant MAX-WEIGHT u1000000000) ;; Maximum weight in kg
(define-constant MAX-VOLUME u10000000) ;; Maximum volume in cubic meters
(define-constant MAX-INSURANCE-VALUE u1000000000000) ;; Maximum insurance value

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

;; Validate string is not empty
(define-private (is-valid-string (str (string-ascii 500)))
  (> (len str) u0)
)

;; Validate dimensions are within reasonable limits
(define-private (is-valid-dimension (value uint))
  (and (> value u0) (<= value MAX-DIMENSIONS))
)

;; Validate capacity is within limits
(define-private (is-valid-capacity (capacity uint))
  (and (> capacity u0) (<= capacity MAX-BERTH-CAPACITY))
)

;; Validate dock fee is within limits
(define-private (is-valid-dock-fee (fee uint))
  (<= fee MAX-DOCK-FEE)
)

;; Validate weight is within limits
(define-private (is-valid-weight (weight uint))
  (and (> weight u0) (<= weight MAX-WEIGHT))
)

;; Validate volume is within limits
(define-private (is-valid-volume (volume uint))
  (and (> volume u0) (<= volume MAX-VOLUME))
)

;; Validate insurance value is within limits
(define-private (is-valid-insurance-value (value uint))
  (<= value MAX-INSURANCE-VALUE)
)

;; Validate ID is non-zero
(define-private (is-valid-id (id uint))
  (> id u0)
)

;; Validate permissions value
(define-private (is-valid-permissions (permissions uint))
  (> permissions u0)
)

;; Validate principal is not the contract itself (prevent self-reference issues)
(define-private (is-valid-principal (addr principal))
  (not (is-eq addr (as-contract tx-sender)))
)

;; Validate authority principal - ensures it's not the contract owner or contract itself
(define-private (is-valid-authority-principal (authority principal))
  (and (not (is-eq authority CONTRACT-OWNER))
       (not (is-eq authority (as-contract tx-sender)))
       (is-valid-principal authority))
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
    ;; Authorization check
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-string name) ERR-INVALID-INPUT)
    (asserts! (is-valid-capacity capacity) ERR-INSUFFICIENT-BERTH-CAPACITY)
    (asserts! (is-valid-dock-fee dock-fee-per-hour) ERR-INVALID-FEE)
    (asserts! (is-valid-string berth-type) ERR-INVALID-INPUT)
    (asserts! (is-valid-dimension depth) ERR-INVALID-DIMENSIONS)
    (asserts! (is-valid-dimension length) ERR-INVALID-DIMENSIONS)
    (asserts! (is-valid-dimension width) ERR-INVALID-DIMENSIONS)
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
    ;; Authorization check
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id berth-id) ERR-INVALID-INPUT)
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
    
    ;; Authorization check
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id berth-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-id vessel-id) ERR-INVALID-INPUT)
    ;; Business logic validation
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
    
    ;; Authorization check
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id berth-id) ERR-INVALID-INPUT)
    ;; Business logic validation
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
    ;; Input validation
    (asserts! (is-valid-string name) ERR-INVALID-INPUT)
    (asserts! (is-valid-string imo-number) ERR-INVALID-INPUT)
    (asserts! (is-valid-string vessel-type) ERR-INVALID-INPUT)
    (asserts! (is-valid-dimension length) ERR-INVALID-DIMENSIONS)
    (asserts! (is-valid-dimension beam) ERR-INVALID-DIMENSIONS)
    (asserts! (is-valid-dimension draft) ERR-INVALID-DIMENSIONS)
    (asserts! (> gross-tonnage u0) ERR-INVALID-INPUT)
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
    ;; Authorization check
    (asserts! (or (is-eq tx-sender (get owner vessel-data)) (is-admin)) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id vessel-id) ERR-INVALID-INPUT)
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
    ;; Input validation
    (asserts! (is-valid-string description) ERR-INVALID-INPUT)
    (asserts! (is-valid-weight weight) ERR-INVALID-WEIGHT)
    (asserts! (is-valid-volume volume) ERR-INVALID-VOLUME)
    (asserts! (is-valid-string cargo-type) ERR-INVALID-INPUT)
    (asserts! (is-valid-principal consignee) ERR-INVALID-INPUT)
    (asserts! (is-valid-id vessel-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-insurance-value insurance-value) ERR-INVALID-INPUT)
    (asserts! (is-valid-string handling-instructions) ERR-INVALID-INPUT)
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
    ;; Authorization check
    (asserts! (or (is-eq tx-sender (get shipper cargo-data)) 
                  (is-eq tx-sender (get consignee cargo-data)) 
                  (is-admin)) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id cargo-id) ERR-INVALID-INPUT)
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
    ;; Authorization check
    (asserts! (is-admin) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id cargo-id) ERR-INVALID-INPUT)
    
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
    
    ;; Input validation
    (asserts! (is-valid-id berth-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-id vessel-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-booking-duration start-time end-time) ERR-INVALID-TIME-SLOT)
    (asserts! (> start-time (get-current-time)) ERR-INVALID-TIME-SLOT)
    (asserts! (is-valid-string special-requirements) ERR-INVALID-INPUT)
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
    ;; Authorization check
    (asserts! (or (is-eq tx-sender (get booker booking-data)) (is-admin)) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id booking-id) ERR-INVALID-INPUT)
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
    ;; Authorization check
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation - validate the authority principal first
    (asserts! (is-valid-authority-principal authority) ERR-INVALID-INPUT)
    (asserts! (is-valid-string role) ERR-INVALID-INPUT)
    (asserts! (is-valid-permissions permissions) ERR-INVALID-INPUT)
    ;; Check if authority already exists
    (asserts! (is-none (map-get? port-authorities { authority: authority })) ERR-AUTHORITY-ALREADY-EXISTS)
    
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
    ;; Authorization check
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation - validate the authority principal first
    (asserts! (is-valid-authority-principal authority) ERR-INVALID-INPUT)
    ;; Check if authority exists before removal
    (asserts! (is-some (map-get? port-authorities { authority: authority })) ERR-AUTHORITY-NOT-FOUND)
    
    (map-delete port-authorities { authority: authority })
    
    (unwrap-panic (log-operation "REMOVE_AUTHORITY" u0 "AUTHORITY" "Port authority removed"))
    (ok true))
)

;; Update port authority status
(define-public (update-authority-status (authority principal) (active bool))
  (let ((authority-data (unwrap! (map-get? port-authorities { authority: authority }) ERR-AUTHORITY-NOT-FOUND)))
    ;; Authorization check
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-authority-principal authority) ERR-INVALID-INPUT)
    
    (map-set port-authorities
      { authority: authority }
      (merge authority-data { active: active })
    )
    
    (unwrap-panic (log-operation "UPDATE_AUTHORITY_STATUS" u0 "AUTHORITY" "Port authority status updated"))
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

;; Get port authority information
(define-read-only (get-port-authority (authority principal))
  (map-get? port-authorities { authority: authority })
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

;; Get all cargo for a vessel (simplified count function)
(define-read-only (get-vessel-cargo-count (vessel-id uint))
  (var-get total-cargo)
)

;; Check if principal is authorized
(define-read-only (is-authorized (principal-addr principal))
  (or (is-eq principal-addr CONTRACT-OWNER)
      (match (map-get? port-authorities { authority: principal-addr })
        authority (get active authority)
        false))
)

;; Get berth occupancy status
(define-read-only (get-berth-occupancy-status (berth-id uint))
  (match (map-get? berths { berth-id: berth-id })
    berth-data {
      berth-id: berth-id,
      status: (get status berth-data),
      vessel-id: (get vessel-id berth-data),
      occupied: (is-eq (get status berth-data) BERTH-STATUS-OCCUPIED)
    }
    { berth-id: berth-id, status: u0, vessel-id: none, occupied: false }
  )
)

;; Get vessel current location
(define-read-only (get-vessel-location (vessel-id uint))
  (match (map-get? vessels { vessel-id: vessel-id })
    vessel-data {
      vessel-id: vessel-id,
      status: (get status vessel-data),
      current-berth: (get current-berth vessel-data),
      is-docked: (is-eq (get status vessel-data) VESSEL-STATUS-DOCKED)
    }
    { vessel-id: vessel-id, status: u0, current-berth: none, is-docked: false }
  )
)

;; Get cargo summary for a vessel
(define-read-only (get-cargo-summary (cargo-id uint))
  (match (map-get? cargo { cargo-id: cargo-id })
    cargo-data {
      cargo-id: cargo-id,
      vessel-id: (get vessel-id cargo-data),
      status: (get status cargo-data),
      customs-cleared: (get customs-cleared cargo-data),
      weight: (get weight cargo-data),
      volume: (get volume cargo-data)
    }
    { cargo-id: cargo-id, vessel-id: u0, status: u0, customs-cleared: false, weight: u0, volume: u0 }
  )
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

;; Emergency berth release (for emergency situations)
(define-public (emergency-release-berth (berth-id uint))
  (let ((berth-data (unwrap! (map-get? berths { berth-id: berth-id }) ERR-BERTH-NOT-FOUND)))
    ;; Authorization check - only contract owner can perform emergency operations
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    ;; Input validation
    (asserts! (is-valid-id berth-id) ERR-INVALID-INPUT)
    
    ;; Force release the berth regardless of current status
    (map-set berths
      { berth-id: berth-id }
      (merge berth-data {
        status: BERTH-STATUS-AVAILABLE,
        vessel-id: none,
        last-updated: (get-current-time)
      })
    )
    
    (unwrap-panic (log-operation "EMERGENCY_RELEASE" berth-id "BERTH" "Emergency berth release"))
    (ok true))
)

;; Pause all port operations
(define-public (pause-port-operations)
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set port-operational false)
    (unwrap-panic (log-operation "PAUSE_OPERATIONS" u0 "PORT" "Port operations paused"))
    (ok true))
)

;; Resume all port operations
(define-public (resume-port-operations)
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set port-operational true)
    (unwrap-panic (log-operation "RESUME_OPERATIONS" u0 "PORT" "Port operations resumed"))
    (ok true))
)