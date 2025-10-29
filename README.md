# Flutter Firebase Authentication App with MongoDB Backend

## Project Overview
A mobile application built with Flutter, featuring Firebase Authentication and MongoDB backend integration. This project demonstrates a complete full-stack implementation with secure user authentication and data management.

## Tech Stack
- Frontend: Flutter
- Authentication: Firebase
- Backend: Node.js, Express
- Database: MongoDB

## Project Structure
```
project/
├── bato-back-end/         # Backend Node.js application
│   ├── config/           # Database configuration
│   ├── controllers/      # Request handlers
│   ├── models/          # Database models
│   ├── routes/          # API routes
│   └── index.js         # Entry point
└── bato_mobile/         # Flutter mobile application
    ├── lib/             # Main Flutter code
    ├── android/         # Android specific code
    ├── ios/            # iOS specific code
    └── assets/         # Application assets
```

## Prerequisites
- Flutter SDK (latest version)
- Node.js (v14 or higher)
- MongoDB
- Firebase account
- Git

## Installation Guide

### Backend Setup
1. Navigate to backend directory:
```bash
cd bato-back-end
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```env
MONGODB_URI=your_mongodb_connection_string
PORT=3000
```

4. Start the server:
```bash
node index.js
```

### Mobile App Setup
1. Navigate to mobile app directory:
```bash
cd bato_mobile
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## Building the APK

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```

APK Location: `bato_mobile/build/app/outputs/flutter-apk/app-release.apk`

## Features
- User Authentication (Sign up, Sign in, Sign out)
- Email verification
- Password reset
- Profile management
- Data persistence with MongoDB
- Secure API endpoints

## Project Configuration

### Firebase Configuration
1. Create a Firebase project
2. Enable Authentication
3. Configure Android/iOS apps
4. Download configuration files

### MongoDB Setup
1. Create MongoDB cluster
2. Configure network access
3. Create database user
4. Get connection string

## Running Tests
```bash
# Backend tests
cd bato-back-end
npm test

# Flutter tests
cd bato_mobile
flutter test
```

## Common Issues & Solutions
- **Firebase Configuration Issues**: Ensure all Firebase configuration files are properly placed
- **MongoDB Connection Errors**: Check network access and credentials
- **Build Errors**: Run `flutter clean` and try rebuilding

## Contributing
1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License
Distributed under the MIT License. See `LICENSE` for more information.


## Acknowledgments
- Flutter Team
- Firebase
- MongoDB
