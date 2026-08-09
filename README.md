# QueueWise - Smart Queue Management

QueueWise is a cross-platform mobile application for virtual queue management. Customers can remotely join service queues using their mobile device instead of physically waiting in line.

## Features

### Customer Features
- User registration and authentication
- Browse and search organisations
- Select services within organisations
- Join virtual queues
- Receive unique sequential queue tokens
- Real-time queue position tracking
- Estimated waiting time calculation
- Queue cancellation
- Queue history viewing

### Admin Features
- Admin dashboard
- View active queues
- Call next customer
- Mark tokens as served
- Mark customers as no-show
- Queue statistics and analytics
- Historical service data
- Average waiting time metrics
- Peak demand analysis

## Technology Stack

### Frontend
- Flutter 3.41.8
- Dart 3.11.5
- Material Design 3

### State Management
- Riverpod 2.6.1

### Backend
- Firebase Authentication
- Cloud Firestore

### Navigation
- go_router 14.8.1

### Development
- Git
- Flutter tooling
- Firebase CLI

### Testing
- Dart unit tests
- Flutter widget tests
- Integration tests
- mocktail 1.0.5

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── constants/
│       └── app_constants.dart
├── core/
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── validators.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   └── firebase_options.dart
│   └── extensions/
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── organisations/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── queues/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── notifications/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── history/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── analytics/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── admin/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── shared/
    ├── widgets/
    ├── models/
    └── providers/
```

## Firebase Setup

### Prerequisites
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create Firestore database

### Configuration
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize project: `firebase init`
4. Configure FlutterFire: `flutterfire configure`
5. Update `lib/core/services/firebase_options.dart` with your Firebase configuration

### Firestore Collections

#### users/{uid}
```dart
{
  'uid': String,
  'name': String,
  'email': String,
  'role': String, // 'customer' or 'admin'
  'createdAt': DateTime,
  'updatedAt': DateTime,
  'notificationEnabled': bool,
}
```

#### organisations/{organisationId}
```dart
{
  'id': String,
  'name': String,
  'description': String,
  'address': String,
  'phone': String,
  'email': String,
  'active': bool,
  'createdAt': DateTime,
  'updatedAt': DateTime
}
```

#### organisations/{organisationId}/services/{serviceId}
```dart
{
  'id': String,
  'name': String,
  'description': String,
  'active': bool,
  'averageServiceDuration': int, // minutes
  'notificationThreshold': int, // people ahead
  'createdAt': DateTime,
  'updatedAt': DateTime
}
```

#### organisations/{organisationId}/queues/{queueId}
```dart
{
  'id': String,
  'organisationId': String,
  'serviceId': String,
  'currentServingNumber': int,
  'nextTokenNumber': int,
  'active': bool,
  'averageServiceDuration': int,
  'totalWaiting': int,
  'updatedAt': DateTime
}
```

#### organisations/{organisationId}/queues/{queueId}/tokens/{tokenId}
```dart
{
  'id': String,
  'queueId': String,
  'organisationId': String,
  'serviceId': String,
  'userId': String,
  'tokenNumber': int,
  'status': String, // 'waiting', 'called', 'serving', 'served', 'cancelled', 'no_show'
  'joinedAt': DateTime,
  'calledAt': DateTime?,
  'servedAt': DateTime?,
  'cancelledAt': DateTime?,
  'estimatedWaitMinutes': int
}
```

#### users/{uid}/queueHistory/{historyId}
```dart
{
  'id': String,
  'organisationId': String,
  'serviceId': String,
  'tokenNumber': int,
  'status': String,
  'joinedAt': DateTime,
  'servedAt': DateTime?,
  'waitingDuration': int, // minutes
  'serviceDuration': int? // minutes
}
```

#### organisations/{organisationId}/analytics/{analyticsId}
```dart
{
  'id': String,
  'serviceId': String,
  'date': DateTime,
  'totalServed': int,
  'totalCancelled': int,
  'totalNoShow': int,
  'averageWaitTime': double,
  'averageServiceTime': double,
  'peakHour': int
}
```

## Environment Configuration

### Android
1. Add `google-services.json` to `android/app/`
2. Update `android/build.gradle` with Google Services classpath
3. Update `android/app/build.gradle` with Google Services plugin

### iOS
1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Update `ios/Runner/Info.plist` with required permissions

## Running the App

### Prerequisites
- Flutter SDK 3.41.8 or higher
- Dart SDK 3.11.5 or higher
- Firebase project configured
- Valid Firebase configuration files

### Steps
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase (see Firebase Setup section)
4. Run the app:
   - Android: `flutter run`
   - iOS: `flutter run`
   - Web: `flutter run -d chrome`

## Running Tests

### Unit Tests
```bash
flutter test test/unit/
```

### Widget Tests
```bash
flutter test test/widget/
```

### Integration Tests
```bash
flutter test integration_test/
```

### All Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Creating an Admin Account

Admin accounts should be created securely through Firebase Console:

1. Go to Firebase Console → Authentication
2. Create a new user with email/password
3. Go to Firestore Database
4. Navigate to `users/{uid}`
5. Update the `role` field to `'admin'`

**Important**: Do not allow users to select admin role during registration.

## Firestore Security Rules

Security rules must enforce:
- Customers can only read public organisation/service data
- Customers can only modify their own tokens and profile
- Customers cannot change their role
- Admins can only manage queues they're authorized for
- Token generation must be atomic
- No public write access to sensitive collections

See `docs/security.md` for detailed security rules.

## Cloud Functions

Cloud Functions are not included in this version to avoid requiring the Firebase Blaze plan. Push notifications can be added in future iterations if needed.

## Deployment

### Android
1. Update version in `pubspec.yaml`
2. Build APK: `flutter build apk --release`
3. Build App Bundle: `flutter build appbundle --release`
4. Upload to Google Play Console

### iOS
1. Update version in `pubspec.yaml`
2. Update iOS version in `ios/Runner/Info.plist`
3. Build: `flutter build ios --release`
4. Archive and upload to App Store Connect

## Known Limitations

- iOS testing requires macOS
- Real-time updates depend on network conditions

## Development Status

### Completed
- ✅ Phase 1: Project foundation and architecture
- ✅ Phase 1: Firebase configuration structure
- ✅ Phase 1: Theme and routing setup
- ✅ Phase 1: Core utilities and error handling
- ✅ Phase 1: Git repository initialization
- ✅ Phase 2: Firebase Authentication (login, register, logout)
- ✅ Phase 2: User Firestore document and role handling
- ✅ Phase 2: Protected routes and auth state management
- ✅ Phase 3: Organisation and Service Firestore models
- ✅ Phase 3: Organisation list with search functionality
- ✅ Phase 3: Service selection screen
- ✅ Phase 4: Queue and Token schema with atomic token generation
- ✅ Phase 4: Queue joining with position calculation
- ✅ Phase 4: Waiting-time calculation service
- ✅ Phase 4: Unit tests for queue calculations
- ✅ Phase 5: Real-time Firestore streams
- ✅ Phase 5: Riverpod providers for queues
- ✅ Phase 5: Active queue screen with live updates
- ✅ Phase 6: Admin routing and dashboard
- ✅ Phase 6: Call next, mark served, mark no-show functionality
- ✅ Phase 8: Customer queue history and admin analytics
- ✅ Phase 9: Firestore security rules and role restrictions (deployed)
- ✅ Phase 10: UI/UX polish and Material Design 3 improvements
- ✅ Phase 11: Comprehensive tests (unit, widget) - 27 tests passing
- ✅ Phase 12: Documentation (architecture, schema, security, setup)
- ✅ Phase 13: User guide documentation
- ✅ Phase 14: Technical report documentation
- ✅ Phase 15: Presentation materials
- ✅ Phase 16: Requirements verification report

### Deployment Status
- ✅ Firebase project configured (queuewise-1a3cc)
- ✅ Authentication enabled (Email/Password)
- ✅ Firestore database created
- ✅ Firestore indexes deployed
- ✅ Firestore security rules deployed
- ✅ Web build complete (build/web/)
- ⚠️ Android build pending (Gradle permission issues on Windows)
- ⚠️ Windows build pending (Developer Mode required)

### All Phases Complete
🎉 QueueWise MVP is now fully implemented with all core features and documentation ready for submission.

## Documentation

- **User Guide**: [docs/USER_GUIDE.md](docs/USER_GUIDE.md) - Complete user manual
- **Technical Report**: [docs/TECHNICAL_REPORT.md](docs/TECHNICAL_REPORT.md) - Detailed technical documentation
- **Presentation Guide**: [docs/PRESENTATION.md](docs/PRESENTATION.md) - Presentation materials and demo script
- **Requirements Verification**: [docs/REQUIREMENTS_VERIFICATION.md](docs/REQUIREMENTS_VERIFICATION.md) - Requirements compliance report

## Project Information

**Team**: Noble Stars  
**Course**: HDIT 21143 - Mobile Software Development  
**Institution**: International Campus of Science and Technology  
**Supervisor**: Ms. P. Niranjana  
**Version**: 1.0.0  
**Date**: August 2026

## Contributing

1. Follow the existing code structure
2. Write tests for new features
3. Run `flutter analyze` before committing
4. Run `flutter test` before committing
5. Follow semantic commit messages

## License

This project is proprietary software. All rights reserved.
