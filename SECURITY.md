# ParkFlow Manager — Security Configuration Guide

This document describes all security measures implemented and the platform-specific
configurations required before production deployment.

## 1. Data-at-Rest Encryption

### SQLCipher Database
- **Status**: Implemented in `lib/core/database/database_provider.dart`
- **Algorithm**: 256-bit AES via SQLCipher 4
- **Key**: 32-byte random key generated via `Random.secure()`, stored in
  `flutter_secure_storage` under key `parkflow_db_encryption_key`
- **Key derivation**: SQLCipher uses PBKDF2-HMAC-SHA512 with 256,000 iterations internally

### Token Storage
- **Status**: Implemented via `flutter_secure_storage`
- **Android**: Uses `EncryptedSharedPreferences` (AES-256-GCM)
- **iOS**: Uses Keychain with `first_unlock` accessibility

## 2. Data-in-Transit Security

### TLS Enforcement
- All API traffic uses HTTPS (enforced via `ApiConstants.baseUrl`)
- Android: `network_security_config.xml` blocks cleartext traffic
- iOS: App Transport Security (ATS) enabled by default

### Certificate Pinning
- **Dart-level**: Implemented in `ApiClient._configureCertificatePinning()`
  using constant-time fingerprint comparison
- **Android-level**: `network_security_config.xml` with SHA-256 pin-set

### HMAC Request Signing
- **Status**: Implemented in `lib/core/security/request_signer.dart`
- **Algorithm**: HMAC-SHA256
- **Signed payload**: `timestamp:method:path:body`
- **Headers**: `X-Request-Timestamp`, `X-Request-Signature`
- **Signed paths**: `/sessions`, `/payments`, `/payments/qr`, `/employees`

## 3. Authentication Security

### Login Throttling
- **Status**: Implemented in `lib/core/security/login_throttle.dart`
- **Threshold**: 3 attempts before lockout
- **Backoff**: Exponential (1s, 2s, 4s... capped at 60s)

### Session Timeout
- **Status**: Implemented in `lib/core/services/session_timeout_service.dart`
- **Timeout**: 15 minutes of inactivity triggers auto-logout
- **Detection**: Pointer events (tap, drag) reset the timer

### Biometric Authentication
- **Status**: Implemented in `lib/core/services/biometric_service.dart`
- **Trigger**: App resume after 2+ minutes in background
- **Fallback**: Device PIN/password accepted
- **Failure**: Logout forced on authentication failure

### Token Refresh
- Separate Dio instance prevents interceptor recursion
- `_isRefreshing` flag prevents concurrent refresh attempts
- Tokens cleared on refresh failure (forces re-login)

## 4. Input Validation

All user inputs are validated via `lib/core/utils/validators.dart`:
- License plates: Alphanumeric + hyphens only, 2-15 chars
- Emails: RFC-compliant regex
- Passwords: 8+ chars, uppercase + digit required
- Names: 2-100 chars, injection characters (`<>{}()[]\;`) rejected
- Payment amounts: Positive, max $99,999.99, max 2 decimal places
- Descriptions: Max 500 chars

## 5. Logging Security

- **Debug builds**: Full request/response logging with PII masking
  (Bearer tokens, license plates, refresh tokens redacted)
- **Release builds**: Logging disabled via `kDebugMode` check
- `SyncService` uses `ProductionFilter` in release mode

## 6. Platform Configuration (Pre-Deployment Checklist)

### Android

1. **Reference network security config in AndroidManifest.xml**:
   ```xml
   <application android:networkSecurityConfig="@xml/network_security_config" ...>
   ```

2. **Enable ProGuard/R8 in android/app/build.gradle**:
   ```groovy
   buildTypes {
       release {
           minifyEnabled true
           shrinkResources true
           proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                         'proguard-rules.pro'
       }
   }
   ```

3. **Prevent screenshots in release** (add to MainActivity):
   ```kotlin
   window.setFlags(
       WindowManager.LayoutParams.FLAG_SECURE,
       WindowManager.LayoutParams.FLAG_SECURE
   )
   ```

4. **Build with obfuscation**:
   ```bash
   flutter build apk --obfuscate --split-debug-info=build/symbols
   ```

### iOS

1. **App Transport Security** — enabled by default. Add exceptions only if needed:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <false/>
   </dict>
   ```

2. **Face ID usage description** in Info.plist:
   ```xml
   <key>NSFaceIDUsageDescription</key>
   <string>Authenticate to access ParkFlow Manager</string>
   ```

3. **Keychain sharing** — disable unless multi-app keychain access is needed.

### Certificate Pinning — Replace Placeholders

Before production, replace placeholder fingerprints in:
- `lib/core/constants/api_constants.dart` → `pinnedCertFingerprints`
- `android/app/src/main/res/xml/network_security_config.xml` → `<pin>` elements

Generate your certificate pins:
```bash
openssl s_client -connect api.parkflow.example.com:443 \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

### HMAC Key Provisioning

The server should return an `hmac_key` field in the login response.
Store it via `RequestSigner.setHmacKey(key)` after successful login.
Clear it via `RequestSigner.clearHmacKey()` on logout.

## 7. Environment Variables

Configure per-environment via `--dart-define`:
```bash
# Development
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1 \
            --dart-define=WS_BASE_URL=ws://10.0.2.2:8080/ws

# Staging
flutter run --dart-define=API_BASE_URL=https://staging.parkflow.com/v1 \
            --dart-define=WS_BASE_URL=wss://staging.parkflow.com/ws

# Production
flutter build apk --dart-define=API_BASE_URL=https://api.parkflow.com/v1 \
                   --dart-define=WS_BASE_URL=wss://api.parkflow.com/ws
```
