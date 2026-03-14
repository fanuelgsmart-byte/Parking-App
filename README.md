# ParkFlow Manager
Parking Lot Management System

## System Functionality & Architecture Requirements
**Version 1.0**  
**March 2026**  
 
### 1. System Overview
ParkFlow Manager is an Android mobile application built for parking lot owners, managers, and employees. It is not a consumer-facing app. The system automates vehicle entry detection via AI-powered cameras, tracks parking duration in real time, calculates fees based on vehicle size, and facilitates payment collection at exit. It also provides comprehensive reporting tools for management.

The application serves two distinct user roles: employees (parking attendants who handle day-to-day lot operations) and managers (who oversee revenue, staffing, and lot configuration).

### 2. How the System Functions
The system operates through four sequential phases from the moment a vehicle enters until the final report is generated.

#### 2.1 Phase 1: Vehicle Entry
1. A vehicle approaches the parking lot entrance.
2. An AI-powered camera automatically scans the vehicle and detects three attributes: license plate number, vehicle size (small, medium, or large), and vehicle color.
3. The system creates a new parking session, recording the vehicle data, assigned spot, and the exact entry timestamp.
4. A billing timer starts automatically. The rate applied depends on the detected vehicle size.

#### 2.2 Phase 2: Active Parking
While the vehicle is parked, the system continuously tracks the session. The employee dashboard displays all active sessions with live duration counters and running fee calculations. The lot map updates in real time, showing which spots are occupied and which are available. No manual intervention is required during this phase.

#### 2.3 Phase 3: Vehicle Exit and Payment
5. When the vehicle moves toward the exit, the system flags the session for checkout.
6. An employee opens the session on the app and views the total fee (duration multiplied by the size-based rate).
7. The employee presents the amount to the customer. The customer pays using one of two methods:
   - **Cash**: The employee collects cash and records the payment in the app.
   - **Digital (QR)**: The app fetches a QR code from the payment provider. The customer scans it from the employee's phone to complete payment.
8. Once payment is confirmed, the session is closed and the spot is freed on the lot map.

#### 2.4 Phase 4: Reporting
All closed sessions feed into the reporting engine. Managers can generate reports on revenue (daily, weekly, monthly, or custom date ranges), lot occupancy and peak hours, per-employee shift performance, and vehicle type revenue breakdowns. Reports can be exported as PDF documents.

### 3. System Capabilities

#### 3.1 Employee Capabilities
| Capability | Description |
|---|---|
| Live session dashboard | View all active parking sessions with live timers, running fees, vehicle details (plate, size, color), and spot assignment. |
| Lot map view | Interactive visual grid of all parking spots showing real-time occupied/available status with vehicle indicators. |
| Checkout and payment | Select a vehicle session, view calculated fee, and process payment via cash recording or QR code fetched from the payment provider. |
| Vehicle search | Search active or past sessions by license plate, vehicle color, or spot number for quick lookup. |
| Shift log | End-of-shift summary showing total vehicles processed, revenue collected (cash vs. digital), and notes for the next shift. |
| Incident logging | Record violations, unauthorized vehicles, or disputes with timestamps and optional notes. |

#### 3.2 Manager Capabilities
| Capability | Description |
|---|---|
| Revenue reports | Generate reports by day, week, month, or custom range. View total revenue, cash vs. digital split, and trends over time. |
| Occupancy analytics | Track peak hours, average parking duration, lot utilization percentage, and identify underused zones. |
| Rate configuration | Set and adjust pricing tiers per vehicle size (small, medium, large). Support for time-of-day and event-based pricing. |
| Employee management | Add, remove, and assign employees to lots or shifts. View per-employee performance: vehicles processed and revenue collected. |
| Multi-lot management | Manage multiple parking lots from a single dashboard with aggregated and per-lot reporting. |
| PDF report export | Export any report as a PDF document for offline sharing or submission to management. |

### 4. Architecture Requirements

#### 4.1 Technology Stack
| Layer | Technology | Justification |
|---|---|---|
| Framework | Flutter 3.38+ / Dart 3.10+ | Industry standard for cross-platform mobile apps. Dominant framework among parking management apps. Delivers 60–120fps rendering for responsive attendant interfaces. |
| State management | BLoC / Cubit | Event-driven architecture provides full audit trail for financial transactions (payments, shift totals). Cubit handles simple UI state; BLoC Events handle complex payment and session flows. |
| Local database | Drift (SQLite ORM) | Type-safe relational queries for linked data (sessions, vehicles, payments, employees). ACID transactions ensure payment records are never partially written. Reactive streams update the UI live. |
| Networking | Dio | Interceptors for automatic auth token injection and silent refresh. Retry logic for unreliable parking lot Wi-Fi. Built-in support for request cancellation and structured error handling. |
| Navigation | go_router | Declarative routing with role-based guards. Managers are routed to the reports dashboard; employees to the live lot view. Prevents unauthorized screen access. |
| Charts | fl_chart | Revenue trend lines, occupancy bar charts, and per-shift comparisons for the manager reporting module. |
| PDF export | pdf + printing | Generate downloadable report PDFs directly on device for offline distribution to lot owners. |
| Data models | freezed + json_serializable | Immutable data classes prevent accidental mutation of completed sessions. Code-generated JSON parsing eliminates manual serialization errors. |
| Dependency injection | get_it + injectable | Clean separation between BLoCs, repositories, and data sources. Makes testing straightforward by swapping real services with mocks. |
| Connectivity | connectivity_plus | Detects online/offline state. Queues transactions locally and syncs when connectivity returns. |

#### 4.2 Security Architecture
Security is critical because the application handles financial data, employee credentials, and vehicle information (license plates). The following measures are required:

| Measure | Implementation |
|---|---|
| Encrypted token storage | flutter_secure_storage uses Android EncryptedSharedPreferences to store auth tokens and API keys. Prevents credential extraction from shared employee devices. |
| Database encryption | sqlcipher_flutter_libs encrypts the entire local Drift/SQLite database at rest. If the device is lost or stolen, vehicle plates and payment records cannot be read. |
| Biometric/PIN lock | local_auth enables fingerprint or PIN verification when switching between employee accounts or accessing payment history. Prevents unauthorized access on shared devices. |
| SSL certificate pinning | Configured via Dio to ensure the app only trusts the specific backend server certificate. Blocks man-in-the-middle attacks on parking lot Wi-Fi networks. |
| Automatic token management | Dio interceptors attach JWT tokens to every API request and handle silent refresh on expiry. Employees are never logged out mid-shift due to token timeout. |
| Role-based access control | Enforced at two levels: client-side (go_router guards prevent navigation to unauthorized screens) and server-side (API rejects requests from insufficient roles). |

#### 4.3 Offline-First Architecture
Parking lots frequently have unreliable internet connectivity. The system must function fully offline and synchronize when the connection is restored.

- **Local-first data**: All parking sessions, payments, and lot state are written to the local Drift database first. The UI always reads from the local database, ensuring zero-latency responsiveness.
- **Background sync**: When connectivity_plus detects a network connection, a sync service pushes queued transactions to the backend and pulls any updates (rate changes, new employee accounts).
- **Conflict resolution**: Server timestamps take precedence. If a rate was changed by the manager while an employee was offline, the new rate applies to sessions created after sync.
- **Graceful degradation**: QR code payment requires network access (to fetch from the payment provider). When offline, only cash payment is available. The app clearly indicates this to the employee.

#### 4.4 Application Architecture Pattern
The application follows Clean Architecture with three layers:

- **Presentation layer**: Flutter widgets, BLoC/Cubit state holders, and go_router navigation. This layer knows nothing about Dio or Drift.
- **Domain layer**: Business logic including fee calculation (duration multiplied by size-based rate), session lifecycle management, and report generation. Uses abstract repository interfaces.
- **Data layer**: Concrete implementations of repositories using Drift (local) and Dio (remote). Handles offline queue, sync, and data mapping between API models and domain entities.

Dependencies flow inward: Presentation depends on Domain, Domain depends on nothing, Data implements Domain interfaces. This separation ensures that swapping the backend, payment provider, or database engine does not require rewriting business logic or UI code.

#### 4.5 External Integrations
| Integration | Purpose | Communication |
|---|---|---|
| AI camera system | Detects license plate, vehicle size, and color at entry. | WebSocket for real-time events pushed to the app when a vehicle is detected. |
| Payment provider | Generates QR codes for digital payment and confirms transactions. | REST API via Dio. App fetches QR image and polls or receives webhook for confirmation. |
| Push notifications | Alerts for lot capacity thresholds, shift reminders, and payment confirmations. | Firebase Cloud Messaging (firebase_messaging package). |
| Backend server | Central data store, user authentication, and report aggregation across lots. | REST API via Dio with JWT authentication and SSL pinning.