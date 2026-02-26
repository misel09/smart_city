# 🏙️ Smart City — Urban Fix Platform

A full-stack mobile application built with **Flutter** and **FastAPI** that bridges the gap between citizens and contractors for efficient urban issue resolution.

---

## 📱 Overview

**Smart City** allows citizens to report urban problems (potholes, broken streetlights, water leaks, etc.) directly from their phones. Contractors can then pick up tasks, resolve them, and upload visual proof. Citizens can track the status of their complaints in real time and leave reviews.

---

## ✨ Features

### 👤 Citizens
- Register / Login with Email & Password or Google Sign-In
- Report urban issues with photo, location (GPS), category, and description
- Track complaint status in real time (`Registered → In Progress → Resolved`)
- View contractor details once a complaint is accepted
- Leave a review after complaint resolution
- View complaints on an interactive map

### 🔧 Contractors
- Register / Login as a contractor with a specific contractor type
- View and filter available complaints (nearby tasks)
- Accept tasks (requires verified mobile number)
- Upload before/after images and resolution description
- View personal work statistics (total, in-progress, resolved)
- Manage profile and mobile number

### 🔐 Authentication
- Email/password registration with password strength validation
- Google Sign-In with role selection
- JWT-based session management

---

## 🛠️ Tech Stack

### Frontend (Flutter)
| Package | Purpose |
|---|---|
| `flutter_map` + `latlong2` | Interactive map view |
| `geolocator` + `geocoding` | GPS & address resolution |
| `image_picker` | Camera / gallery image upload |
| `provider` | State management |
| `google_sign_in` | Google OAuth |
| `cached_network_image` | Efficient image loading |
| `google_fonts` | Custom typography |
| `shared_preferences` | Local session storage |

### Backend (Python / FastAPI)
| Tech | Purpose |
|---|---|
| `FastAPI` | REST API framework |
| `SQLAlchemy` | ORM for database models |
| `PostgreSQL` | Primary database |
| `python-jose` | JWT authentication |
| `bcrypt` | Password hashing |
| `Pydantic` | Data validation |
| `uvicorn` | ASGI server |

---

## 📁 Project Structure

```
smart_city/
├── lib/
│   ├── core/
│   │   ├── config/         # API configuration
│   │   └── theme/          # App colors & theme
│   └── features/
│       ├── auth/           # Login, Register, Google Sign-In
│       ├── home/           # Citizen dashboard, map, report issue
│       ├── reports/        # Complaint details, status timeline
│       ├── contractor/     # Contractor dashboard, tasks, profile
│       ├── profile/        # Citizen profile page
│       └── splash/         # Splash screen
├── backend/
│   ├── main.py             # FastAPI app entry point
│   ├── models.py           # SQLAlchemy DB models
│   ├── schemas.py          # Pydantic schemas
│   ├── auth.py             # JWT & authentication logic
│   ├── database.py         # DB connection setup
│   ├── routers/            # API route handlers
│   └── requirements.txt    # Python dependencies
└── assets/
    └── images/             # App assets
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Dart ≥ 3.10)
- [Python 3.10+](https://www.python.org/)
- [PostgreSQL](https://www.postgresql.org/)
- A Firebase project (for Google Sign-In)

---

### 🔧 Backend Setup

```bash
# Navigate to backend
cd backend

# Create a virtual environment
python -m venv venv
venv\Scripts\activate      # Windows
# source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt
```

Create a `.env` file inside `backend/`:
```env
DATABASE_URL=postgresql://username:password@localhost/smart_city_db
SECRET_KEY=your_jwt_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

```bash
# Run the backend server
uvicorn main:app --reload
```

API will be available at: `http://localhost:8000`  
Docs at: `http://localhost:8000/docs`

---

### 📱 Flutter App Setup

```bash
# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

> ⚠️ **Important:** The `google-services.json` (Firebase config) is excluded from this repo for security. You must add your own `android/app/google-services.json` from your Firebase console.

Update the API base URL in `lib/core/config/api_config.dart` to point to your backend server.

---

## 📊 Complaint Status Flow

```
Registered  →  In Progress  →  Resolved
   (Citizen        (Contractor      (Contractor
   submits)        accepts task)    uploads proof)
                                        ↓
                                  Citizen leaves
                                    a review
```

---

## 🔒 Security Notes

- Passwords are hashed using `bcrypt`
- Sessions are managed with JWT tokens
- Firebase credentials (`google-services.json`) are **not committed** to the repo
- Contractors must verify their mobile number before accepting tasks

---

## 🤝 Contributing

1. Fork the repository
2. Create a new branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is for educational/academic purposes.

---

> Built with ❤️ using Flutter & FastAPI
