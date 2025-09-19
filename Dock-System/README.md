# Decentralized Port Management Smart Contract

## Overview

This smart contract provides a comprehensive decentralized solution for managing port operations including berth allocation, vessel management, cargo tracking, and booking systems. Built on the Stacks blockchain using Clarity language, it ensures transparent, secure, and efficient port operations.

## Features

- **Berth Management**: Create, allocate, and manage port berths with detailed specifications
- **Vessel Registration**: Register and track vessels with comprehensive maritime information
- **Cargo Tracking**: Full lifecycle cargo management from arrival to clearance
- **Booking System**: Advanced berth booking with time slot management
- **Access Control**: Role-based permissions for port authorities
- **Audit Trail**: Complete operation logging for compliance and transparency

## Contract Constants

### Error Codes
- `ERR-UNAUTHORIZED-ACCESS (100)`: Access denied for unauthorized users
- `ERR-BERTH-NOT-FOUND (101)`: Requested berth does not exist
- `ERR-BERTH-ALREADY-OCCUPIED (102)`: Berth is currently occupied
- `ERR-BERTH-NOT-OCCUPIED (103)`: Berth is not occupied
- `ERR-INVALID-VESSEL-ID (104)`: Invalid vessel identifier
- `ERR-VESSEL-ALREADY-EXISTS (105)`: Vessel already registered
- `ERR-VESSEL-NOT-FOUND (106)`: Vessel not found in system
- `ERR-CARGO-NOT-FOUND (107)`: Cargo record not found
- `ERR-CARGO-ALREADY-EXISTS (108)`: Cargo already registered
- `ERR-INVALID-CARGO-STATUS (109)`: Invalid cargo status value
- `ERR-BERTH-ALREADY-EXISTS (110)`: Berth already exists
- `ERR-INSUFFICIENT-BERTH-CAPACITY (111)`: Berth capacity exceeds maximum
- `ERR-INVALID-TIME-SLOT (112)`: Invalid booking time slot
- `ERR-BOOKING-NOT-FOUND (113)`: Booking record not found
- `ERR-BOOKING-ALREADY-EXISTS (114)`: Booking already exists
- `ERR-INVALID-BOOKING-STATUS (115)`: Invalid booking status

### Operational Constants
- `MAX-BERTH-CAPACITY`: 10,000 units maximum berth capacity
- `MIN-BOOKING-DURATION`: 1 hour minimum booking
- `MAX-BOOKING-DURATION`: 168 hours (7 days) maximum booking

### Status Constants

#### Berth Status
- `BERTH-STATUS-AVAILABLE (1)`: Berth available for allocation
- `BERTH-STATUS-OCCUPIED (2)`: Berth currently occupied
- `BERTH-STATUS-MAINTENANCE (3)`: Berth under maintenance

#### Vessel Status
- `VESSEL-STATUS-DOCKED (1)`: Vessel docked at berth
- `VESSEL-STATUS-ANCHORED (2)`: Vessel anchored in port
- `VESSEL-STATUS-DEPARTED (3)`: Vessel departed from port

#### Cargo Status
- `CARGO-STATUS-PENDING (1)`: Cargo awaiting processing
- `CARGO-STATUS-LOADING (2)`: Cargo being loaded
- `CARGO-STATUS-LOADED (3)`: Cargo loaded on vessel
- `CARGO-STATUS-UNLOADING (4)`: Cargo being unloaded
- `CARGO-STATUS-UNLOADED (5)`: Cargo unloaded from vessel
- `CARGO-STATUS-CLEARED (6)`: Cargo cleared for delivery

#### Booking Status
- `BOOKING-STATUS-PENDING (1)`: Booking awaiting confirmation
- `BOOKING-STATUS-CONFIRMED (2)`: Booking confirmed
- `BOOKING-STATUS-ACTIVE (3)`: Booking currently active
- `BOOKING-STATUS-COMPLETED (4)`: Booking completed
- `BOOKING-STATUS-CANCELLED (5)`: Booking cancelled

## Data Structures

### Berths
```clarity
{
  name: string-ascii 50,
  capacity: uint,
  status: uint,
  vessel-id: optional uint,
  dock-fee-per-hour: uint,
  berth-type: string-ascii 20,
  depth: uint,
  length: uint,
  width: uint,
  created-at: uint,
  last-updated: uint
}
```

### Vessels
```clarity
{
  name: string-ascii 100,
  imo-number: string-ascii 20,
  owner: principal,
  vessel-type: string-ascii 30,
  length: uint,
  beam: uint,
  draft: uint,
  gross-tonnage: uint,
  status: uint,
  current-berth: optional uint,
  arrival-time: optional uint,
  departure-time: optional uint,
  created-at: uint,
  last-updated: uint
}
```

### Cargo
```clarity
{
  description: string-ascii 200,
  weight: uint,
  volume: uint,
  cargo-type: string-ascii 50,
  shipper: principal,
  consignee: principal,
  vessel-id: uint,
  status: uint,
  berth-id: optional uint,
  customs-cleared: bool,
  insurance-value: uint,
  handling-instructions: string-ascii 300,
  created-at: uint,
  last-updated: uint
}
```

### Berth Bookings
```clarity
{
  berth-id: uint,
  vessel-id: uint,
  booker: principal,
  start-time: uint,
  end-time: uint,
  total-fee: uint,
  status: uint,
  special-requirements: string-ascii 200,
  created-at: uint,
  last-updated: uint
}
```

## Public Functions

### Berth Management

#### `create-berth`
Creates a new berth with specified parameters.

**Parameters:**
- `name`: Berth name (string-ascii 50)
- `capacity`: Berth capacity (uint)
- `dock-fee-per-hour`: Hourly docking fee (uint)
- `berth-type`: Type of berth (string-ascii 20)
- `depth`: Berth depth (uint)
- `length`: Berth length (uint)
- `width`: Berth width (uint)

**Returns:** Berth ID (uint)

**Authorization:** Admin only

#### `update-berth-status`
Updates the status of an existing berth.

**Parameters:**
- `berth-id`: Target berth ID (uint)
- `new-status`: New status value (uint)

**Returns:** Success boolean

**Authorization:** Admin only

#### `allocate-berth`
Allocates a berth to a vessel.

**Parameters:**
- `berth-id`: Target berth ID (uint)
- `vessel-id`: Target vessel ID (uint)

**Returns:** Success boolean

**Authorization:** Admin only

#### `deallocate-berth`
Deallocates a berth from its current vessel.

**Parameters:**
- `berth-id`: Target berth ID (uint)

**Returns:** Success boolean

**Authorization:** Admin only

### Vessel Management

#### `register-vessel`
Registers a new vessel in the system.

**Parameters:**
- `name`: Vessel name (string-ascii 100)
- `imo-number`: IMO registration number (string-ascii 20)
- `vessel-type`: Type of vessel (string-ascii 30)
- `length`: Vessel length (uint)
- `beam`: Vessel beam width (uint)
- `draft`: Vessel draft (uint)
- `gross-tonnage`: Gross tonnage (uint)

**Returns:** Vessel ID (uint)

**Authorization:** Any user

#### `update-vessel-status`
Updates the status of a vessel.

**Parameters:**
- `vessel-id`: Target vessel ID (uint)
- `new-status`: New status value (uint)

**Returns:** Success boolean

**Authorization:** Vessel owner or admin

### Cargo Management

#### `create-cargo`
Creates a new cargo entry.

**Parameters:**
- `description`: Cargo description (string-ascii 200)
- `weight`: Cargo weight (uint)
- `volume`: Cargo volume (uint)
- `cargo-type`: Type of cargo (string-ascii 50)
- `consignee`: Recipient address (principal)
- `vessel-id`: Associated vessel ID (uint)
- `insurance-value`: Insurance value (uint)
- `handling-instructions`: Special instructions (string-ascii 300)

**Returns:** Cargo ID (uint)

**Authorization:** Any user

#### `update-cargo-status`
Updates cargo status.

**Parameters:**
- `cargo-id`: Target cargo ID (uint)
- `new-status`: New status value (uint)

**Returns:** Success boolean

**Authorization:** Shipper, consignee, or admin

#### `clear-cargo-customs`
Clears cargo through customs.

**Parameters:**
- `cargo-id`: Target cargo ID (uint)

**Returns:** Success boolean

**Authorization:** Admin only

### Booking Management

#### `create-berth-booking`
Creates a new berth booking.

**Parameters:**
- `berth-id`: Target berth ID (uint)
- `vessel-id`: Target vessel ID (uint)
- `start-time`: Booking start time (uint)
- `end-time`: Booking end time (uint)
- `special-requirements`: Special requirements (string-ascii 200)

**Returns:** Booking ID (uint)

**Authorization:** Any user

#### `update-booking-status`
Updates booking status.

**Parameters:**
- `booking-id`: Target booking ID (uint)
- `new-status`: New status value (uint)

**Returns:** Success boolean

**Authorization:** Booker or admin

### Authority Management

#### `add-port-authority`
Adds a new port authority with specified role and permissions.

**Parameters:**
- `authority`: Principal address of authority (principal)
- `role`: Authority role description (string-ascii 50)
- `permissions`: Permission level (uint)

**Returns:** Success boolean

**Authorization:** Contract owner only

#### `remove-port-authority`
Removes a port authority.

**Parameters:**
- `authority`: Principal address to remove (principal)

**Returns:** Success boolean

**Authorization:** Contract owner only

### Emergency Functions

#### `set-port-operational`
Sets the operational status of the entire port.

**Parameters:**
- `operational`: Port operational status (bool)

**Returns:** Success boolean

**Authorization:** Contract owner only

## Read-Only Functions

### `get-berth`
Retrieves berth information by ID.

### `get-vessel`
Retrieves vessel information by ID.

### `get-cargo`
Retrieves cargo information by ID.

### `get-booking`
Retrieves booking information by ID.

### `get-operation-log`
Retrieves operation log by ID.

### `get-port-stats`
Returns comprehensive port statistics including total counts and operational status.

### `is-berth-available`
Checks if a specific berth is available for allocation.

### `get-vessel-cargo-count`
Returns the total count of cargo entries for a vessel.

## Access Control

The contract implements a three-tier access control system:

1. **Contract Owner**: Full administrative privileges, can manage port authorities
2. **Port Authorities**: Operational privileges for managing berths, vessels, and cargo
3. **General Users**: Can register vessels, create cargo entries, and make bookings

## Audit Trail

All operations are logged with comprehensive details including:
- Operation type and timestamp
- Entity ID and type
- Operator principal
- Operation details

## Usage Examples

### Register a Vessel
```clarity
(contract-call? .port-management register-vessel 
  "MV Ocean Star" 
  "IMO1234567" 
  "Container Ship" 
  u300 
  u48 
  u16 
  u50000)
```

### Create a Berth
```clarity
(contract-call? .port-management create-berth 
  "Berth A1" 
  u5000 
  u100 
  "Container" 
  u15 
  u350 
  u50)
```

### Allocate Berth to Vessel
```clarity
(contract-call? .port-management allocate-berth u1 u1)
```

## Security Considerations

- All state-changing operations require appropriate authorization
- Input validation prevents invalid data entry
- Comprehensive error handling with descriptive error codes
- Complete audit trail for all operations
- Role-based access control system