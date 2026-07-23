# 🇻🇳 Vietnam Map Dashboard (PRM393)

A Flutter application for managing and visualizing administrative information in Vietnam. The system provides interactive maps, household management, incident management, historical site management, and role-based administration using Firebase services.

## Features

### User
- Login / Logout
- Update profile
- View interactive Vietnam map
- View province, commune, and high school information
- Create household registration requests
- Create, update, and delete incidents
- Receive notifications

### Administrator
- Dashboard
- Approve or reject household requests
- Assign and update incident status
- Manage historical sites
- Manage users
- View reports and statistics

## Technology Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging (FCM)
- Provider
- Google Maps

## Testing

This project includes:

- Unit Tests
- Widget Tests
- Code Coverage
- SonarCloud static code analysis
- GitHub Actions CI

Run tests locally:

```bash
flutter test
```

Generate coverage:

```bash
flutter test --coverage
```

## Project Structure

```
lib/
 ├── models/
 ├── providers/
 ├── services/
 ├── screens/
 ├── widgets/
 └── utils/

test/
 ├── models/
 ├── providers/
 ├── services/
 └── widgets/
```

## Authors

PRM393 - Vietnam Map Project