# 🏙️ Smart City — AI-Powered Urban Resolution Engine

![Release](https://img.shields.io/badge/Release-v1.0.0--Stable-success?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Production-005863?style=for-the-badge&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Managed-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

> **Architecting the future of urban resilience through real-time geospatial incident response, AI-driven diagnostics, and transparent stakeholder orchestration.**

Smart City is an enterprise-grade, full-stack ecosystem engineered to bridge the communication gap between **Citizens**, **Contractors**, and **Municipal Officers**. By digitizing the reporting and resolution lifecycle of urban infrastructure issues, the platform drastically reduces resolution latency and ensures high-fidelity public accountability.

---

## 🏛️ Comprehensive Platform Overview

Smart City is not just an app; it's a **collaborative urban framework**. It transforms every citizen into a sensor for the city, every contractor into a verified resolver, and every official into a data-driven leader.

### 👥 Stakeholder Roles & Workflows

#### 1. 👤 The Citizen Experience (Reporting & Transparency)
*   **Intuitive Reporting**: Citizens can capture a photo of an issue (e.g., a pothole or a broken light). Using **AI Image Analysis**, the app automatically suggests the category, description, and priority level, making reporting a 10-second task.
*   **Geospatial Awareness**: Reports are automatically tagged with precise GPS coordinates. Citizens can view these on a high-definition map, using a **Dynamic Radius Selector (10km, 25km, 50km)** to see what else is happening in their local community.
*   **Trust & Verification**: Once a report is submitted, citizens receive real-time updates. They can see exactly when a contractor accepts the task and can review the "Proof of Resolution" photo before closing the case.

#### 2. 🔧 The Contractor Portal (Action & Efficiency)
*   **Proximity-Based Task Discovery**: Using the **Haversine Distance Algorithm**, contractors are presented with a prioritized feed of tasks nearby. This ensures they spend less time traveling and more time fixing.
*   **Specialized Filtering**: Contractors only see tasks relevant to their expertise (e.g., an Electrician sees "Broken Streetlights", but not "Water Leaks").
*   **Verified Resolution**: To close a task, contractors must upload a "Before and After" comparison, documented with a resolution description. This data is instantly synced back to the citizen and the municipal office.

#### 3. 👮 The Municipal Command Center (Officers)
*   **Macro-Level Oversight**: Officers have access to a **District Dashboard**, filtering all complaints within their specific jurisdiction.
*   **Analytical Mapping**: A heatmap-style visualization helps officers identify "painless points" where infrastructure failures are frequent, allowing for long-term preventative maintenance.

---

## 🛠️ Advanced Technical Stack

### 📱 Frontend Architecture (Flutter / Dart)
*   **Geospatial Engine**: Powered by `flutter_map`. It handles high-density tile rendering and dynamic radius visualization using a custom `CircleLayer`.
*   **Reactive State**: Uses `Provider` to ensure that when a status updates on the server, the UI (including the map markers and lists) reflects it instantly.
*   **Modern UI/UX**: Implements a high-end "Glassmorphism" design system with deep blue and slate palettes, vibrant primary accents, and smooth micro-animations.

### 🐍 Backend Infrastructure (FastAPI / PostgreSQL)
*   **High-Concurrency Kernel**: Built on **FastAPI**, leveraging Python's `async/await` for sub-millisecond response times under load.
*   **Data Integrity**: **PostgreSQL** serves as the primary relational core, ensuring ACID compliance across complex user-contractor-incident relationships.
*   **Security Protocol**: 
    *   **Authentication**: Industry-standard **JWT** (JSON Web Tokens) with HS256 encryption.
    *   **Password Safety**: Forced salting and hashing via `Bcrypt`.
    *   **Role Isolation**: Strict **RBAC** (Role-Based Access Control) ensures users only access data relevant to their role.

---

## 🤖 AI Diagnostics & Intelligence

Smart City features a sophisticated **AI Integration Layer** utilizing **Google Gemini Pro Vision**:
*   **Visual Diagnostics**: When a citizen uploads a photo, the AI analyzes the pixels to identify the issue type and severity.
*   **Automated Priority**: Crucial safety hazards (like exposed wires or massive sinkholes) are automatically marked as **"High Priority"**, pushing them to the top of the contractor's feed.
*   **Semantic Assistance**: Automatically generates descriptive text for reports, ensuring contractors have clear technical context even if the citizen is unsure of the terminology.

---

## 🚀 Deployment & Configuration

### 🔧 Backend Environment
1.  **Repository Ingestion**:
    ```bash
    cd backend && python -m venv venv
    source venv/bin/activate # Windows: venv\Scripts\activate
    pip install -r requirements.txt
    ```
2.  **Environment Setup**: Configure `backend/.env` with your `DATABASE_URL`, `SECRET_KEY`, and `GEMINI_API_KEY`.
3.  **Bootstrap**:
    ```bash
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
    ```

### 📱 Mobile Application
1.  **Initialize**:
    ```bash
    flutter pub get
    ```
2.  **Service Linkage**: Add your Firebase `google-services.json` to `android/app/`.
3.  **Execute**:
    ```bash
    flutter run
    ```

---

## 🔒 Enterprise Security Standards

*   **Multi-Factor Verification**: OTP-based mobile verification for all critical stakeholder actions (Registration & Password Recovery).
*   **Role-Based Data Isolation**: Contractors and Officers can only access data pertinent to their specialized roles or districts.
*   **Encrypted Communication**: All data in transit is protected via standard TLS/SSL protocols.

---

> **Smart City** — Engineering sustainable, responsive, and data-driven urban environments.
