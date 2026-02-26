# PRACTICAL LAB 3: Development Environment Setup & Project Structure
## Smart City Mobile Application

---

## 1. Introduction

A well-structured project is the backbone of any successful mobile application. In this lab, we established a professional development environment for the **Smart City** mobile application using Flutter, Android Studio, and a Python FastAPI backend. We implemented a scalable, modular architecture that separates concerns (UI, Business Logic, Services, Models, Utilities), ensuring the codebase remains maintainable for advanced features like real-time data integration, state management, and backend API synchronization.

---

## 2. ENVIRONMENT SETUP

### 2.1 Tools Installed

The following tools were successfully installed and configured:

| Tool | Purpose | Status |
|------|---------|--------|
| **Flutter SDK** | Cross-platform mobile development framework | ✓ Installed |
| **Android Studio** | Android SDK, Emulator, and development tools | ✓ Installed |
| **VS Code** | Primary IDE for coding | ✓ Installed |
| **Python 3.x** | Backend API development (FastAPI) | ✓ Installed |
| **Git** | Version control | ✓ Configured |

### 2.2 Verification (Flutter Doctor)

The environment was verified using the `flutter doctor` command:

```bash
flutter doctor
```

**Status Summary:**
- ✓ Flutter SDK: 3.38.7 (Channel stable)
- ✓ Windows Version: 11 Home Single Language 64-bit
- ⚠ Android SDK: Version 36.1.0 (cmdline-tools installation needed)
- ✓ Chrome: Web development ready
- ✓ Connected Devices: Multiple targets available (Windows, Chrome, Edge)

---

## 3. PROJECT CREATION & STRUCTURE

### 3.1 Project Initialization

The Smart City project was initialized using Flutter CLI:

```bash
flutter create smart_city
```

### 3.2 Scalable Folder Structure

The project follows a **Feature-First Architecture** with clear separation of concerns:

```
smart_city/
├── lib/
│   ├── main.dart                    # Application entry point
│   │
│   ├── core/
│   │   ├── constants/               # App-wide constants (API endpoints, timeouts)
│   │   └── theme/                   # Global theme configuration (colors, typography)
│   │
│   ├── features/                    # Feature modules (scalable architecture)
│   │   ├── auth/                    # Authentication feature
│   │   │   ├── screens/             # Login, Register, Onboarding screens
│   │   │   ├── widgets/             # Auth-specific widgets
│   │   │   ├── models/              # User models
│   │   │   └── providers/           # Auth state management
│   │   │
│   │   └── home/                    # Home/Dashboard feature
│   │       ├── screens/             # Dashboard, City Map, Reports
│   │       ├── widgets/             # Dashboard-specific components
│   │       ├── models/              # City data models
│   │       └── providers/           # Home state management
│   │
│   ├── shared/                      # Shared across all features
│   │   ├── widgets/                 # Reusable components (AppBar, Cards, Buttons)
│   │   ├── services/                # API calls, Database, Authentication service
│   │   ├── models/                  # Global data models (API Response, User)
│   │   └── utils/                   # Helper functions, date formatting, validators
│   │
│   └── assets/
│       ├── images/                  # App images and icons
│       └── fonts/                   # Custom fonts
│
├── android/                         # Android-specific configuration
│   ├── app/
│   │   └── src/                     # Android source files
│   ├── build.gradle.kts
│   └── gradle.properties
│
├── ios/                             # iOS-specific configuration
├── web/                             # Web platform files
├── windows/                         # Windows desktop files
├── linux/                           # Linux desktop files
├── macos/                           # macOS configuration
│
├── backend/                         # FastAPI Backend Service
│   ├── main.py                      # FastAPI application entry
│   ├── auth.py                      # Authentication logic
│   ├── database.py                  # Database connection/models
│   ├── models.py                    # Pydantic data models
│   ├── schemas.py                   # Request/Response schemas
│   ├── requirements.txt             # Python dependencies
│   └── routers/                     # API endpoint routers
│       └── auth.py                  # Auth endpoints
│
├── test/                            # Widget and unit tests
├── build/                           # Generated build files
├── pubspec.yaml                     # Flutter dependencies and metadata
├── pubspec.lock                     # Locked dependency versions
├── analysis_options.yaml            # Dart analysis rules
├── README.md                        # Project documentation
└── smart_city.iml                   # IDE project file
```

### 3.3 Architecture Rationale

**Feature-Based Organization:**
- Each feature is self-contained (auth, home, etc.)
- Easy to scale: Add new features without affecting existing code
- Team collaboration: Multiple developers can work on different features simultaneously

**Shared Resources:**
- `services/`: Centralized API communication, database access, and authentication
- `shared/widgets/`: Reusable UI components reduce duplication
- `core/`: Global settings ensure consistency across the app

---

## 4. CONFIGURATION & DEPENDENCIES

### 4.1 App Configuration

#### 4.1.1 pubspec.yaml Configuration

```yaml
name: smart_city
description: A comprehensive smart city management and monitoring application.
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.0
  
  # API & Networking
  http: ^1.1.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  
  # Additional utilities
  intl: ^0.19.0
```

#### 4.1.2 Theme Configuration

**File:** `lib/core/theme/app_theme.dart`

A global theme was defined to standardize colors, typography, and UI patterns:

```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF0066CC),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0066CC),
        secondary: Color(0xFF00D9FF),
      ),
      useMaterial3: true,
    );
  }
}
```

**Benefits:**
- Consistent branding across all screens
- Easy theme switching (light/dark mode support in future)
- Centralized color and typography management

### 4.2 Dependencies Added

Essential packages were added to `pubspec.yaml`:

| Package | Version | Purpose |
|---------|---------|---------|
| **provider** | ^6.0.0 | State management for reactive UI updates |
| **http** | ^1.1.0 | HTTP requests to FastAPI backend |
| **shared_preferences** | ^2.2.0 | Local persistent data storage |
| **intl** | ^0.19.0 | Internationalization and date formatting |

### 4.3 Backend Configuration (FastAPI)

**File:** `backend/requirements.txt`

```
fastapi==0.104.1
uvicorn==0.24.0
sqlalchemy==2.0.23
pydantic==2.5.0
python-jose==3.3.0
passlib==1.7.4
python-multipart==0.0.6
```

---

## 5. EXECUTION & OUTPUT

### 5.1 Starting the Android Emulator

**Steps:**
1. Open Android Studio
2. Navigate to **Tools → Device Manager**
3. Click **Play** on an available emulator (e.g., Pixel 6, API 34)
4. Wait for the emulator to fully load

### 5.2 Running the Flutter Application

Execute the following command in the project root:

```bash
cd d:\Languages\projects\smart_city
flutter run
```

**Expected Output:**
```
Launching lib/main.dart on [Emulator Device] in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk (15.3MB).

Installing and launching...
✓ Installed application on emulator.

Application started on emulator device.
```

### 5.3 Application Status

✓ **Project successfully initialized**  
✓ **Folder structure organized** for scalability  
✓ **Dependencies configured** and ready  
✓ **Theme setup complete**  
✓ **Backend API structure established**  

---

## 6. NEXT STEPS (Future Labs)

1. **Authentication Implementation:** Login/Register screens with JWT token handling
2. **API Integration:** Connect frontend to FastAPI backend
3. **State Management:** Implement Provider for user session management
4. **Real-time Features:** WebSocket integration for live city data
5. **Database Integration:** Local SQLite for offline support
6. **Testing:** Unit tests and widget tests
7. **Deployment:** Build APK for Android and prepare for Play Store

---

## 7. TROUBLESHOOTING

### Issue: Android SDK/Emulator not found

**Solution:**
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Download Android SDK
# Open Android Studio → SDK Manager → Install required SDKs
```

### Issue: Slow emulator startup

**Alternative:** Use a physical Android device
```bash
flutter devices  # List connected devices
flutter run -d <device-id>
```

### Issue: Dependencies not resolving

**Solution:**
```bash
flutter pub get
flutter pub upgrade
flutter clean
flutter pub get
```

---

## 8. CONCLUSION

The Smart City application now has a solid foundation with:
- ✓ Professional project structure for scalability
- ✓ Clear separation of concerns (Features, Services, Models, UI)
- ✓ Essential dependencies configured
- ✓ Global theme and configuration setup
- ✓ Backend API structure ready for integration

This architecture supports multiple developers, maintains code quality, and enables rapid feature development while keeping the codebase clean and maintainable.

---

**Document Version:** 1.0  
**Date:** January 28, 2026  
**Project:** Smart City Mobile Application
