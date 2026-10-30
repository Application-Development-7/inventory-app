# 📦 Stockwise - Inventory Management System

A modern, full-stack Inventory Management System designed with a SaaS-style dashboard. It features real-time stock tracking, AI-powered demand forecasting, and a beautiful, responsive UI that works seamlessly on Web, Desktop, and Mobile.

## ✨ Features

*   **Modern UI/UX:** Responsive SaaS dashboard with a sidebar navigation, data tables, and soft, friendly animations.
*   **AI Demand Forecasting:** Analyzes historical stock movements to predict future demand (Monthly and Yearly views).
*   **Smart Recommendations:** A rule-based AI engine that suggests when to restock, reduce orders, or take urgent action based on trends.
*   **Inventory Management:** Full CRUD (Create, Read, Update, Delete) functionality for products and categories.
*   **Low Stock Alerts:** Instant visual warnings for products falling below their minimum stock levels.
*   **Privacy Toggle:** Hide sensitive data like total Inventory Value with a single click.
*   **Dark Mode:** Fully integrated light and dark themes.
*   **Philippine Peso (₱) Support:** All prices and values are formatted for the local market.
*   **Secure Authentication:** JWT-based login system with route protection.

## 🛠️ Tech Stack

**Frontend:**
*   Flutter (Dart)
*   `provider` (State Management)
*   `fl_chart` (Data Visualization)
*   `google_fonts` (Typography)
*   `shared_preferences` (Local Token Storage)

**Backend:**
*   Node.js & Express.js
*   MySQL2 (Database driver)
*   JWT (JSON Web Tokens for Auth)
*   Bcrypt (Password Hashing)

**Database:**
*   MySQL (Community Server)
*   **Architecture:** 100% Stored Procedures. (The backend strictly uses `CALL sp_xxx()` to interact with the database; no raw SQL queries exist in the Node.js code).

---

## 🚀 Getting Started (Local Setup)

### Prerequisites
Make sure you have installed:
*   [Node.js](https://nodejs.org/) (LTS version)
*   [MySQL Community Server & Workbench](https://dev.mysql.com/downloads/installer/)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   [Android Studio](https://developer.android.com/studio) (For the emulator)
*   [VS Code](https://code.visualstudio.com/)

### 1. Database Setup
1. Open **MySQL Workbench** and connect to your local instance.
2. Create a new database named `inventory_db`.
3. Run the SQL scripts provided in the `/database` folder (or the root of the repo) to create the tables, stored procedures, and seed data. 
   *(Ensure you run the scripts for `sp_get_dashboard_summary`, `sp_get_all_products`, `sp_get_top_products_by_month`, etc.)*

### 2. Backend Setup
1. Open a terminal and navigate to the backend folder:
   ```bash
   cd inventory-backend