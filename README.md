# Smart Kirana - Flutter App

A complete **retail store management** mobile application built with Flutter and Supabase.

---

## 🚀 Setup Instructions

### 1. Install Flutter
```bash
winget install Google.Flutter
# Then restart terminal and verify:
flutter doctor
```

### 1a. Windows Desktop Requirements (Optional)
If you want to run the app as a **Windows Desktop** application (Option 1 in `flutter run`), you must install:
1.  **Visual Studio 2022** (Community Edition is fine).
2.  During installation, select the **"Desktop development with C++"** workload.
3.  Ensure the **Windows 10/11 SDK** is checked.

*Note: If you don't want to install Visual Studio, you can run the app on **Chrome** or **Edge** (Web).*

### 2. Create Supabase Project
1. Go to [supabase.com](https://supabase.com) → Create new project
2. Copy your **Project URL** and **Anon Key** from Settings → API

### 3. Configure Credentials
Open `lib/core/constants/app_constants.dart` and replace:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. Run Supabase Database Migration
In your Supabase SQL Editor, run:

```sql
-- Products table
CREATE TABLE products (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  cost_price DECIMAL(10,2) DEFAULT 0,
  quantity INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,
  supplier TEXT,
  barcode TEXT,
  unit TEXT DEFAULT 'piece',
  is_active BOOLEAN DEFAULT true,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  total_credit DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bills table
CREATE TABLE bills (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  customer_id UUID REFERENCES customers(id),
  customer_name TEXT,
  subtotal DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  payment_mode TEXT NOT NULL,
  amount_paid DECIMAL(10,2) DEFAULT 0,
  credit_amount DECIMAL(10,2) DEFAULT 0,
  status TEXT DEFAULT 'completed',
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bill Items table
CREATE TABLE bill_items (
  id UUID PRIMARY KEY,
  bill_id UUID NOT NULL REFERENCES bills(id),
  product_id UUID NOT NULL,
  product_name TEXT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  quantity INTEGER NOT NULL,
  total_price DECIMAL(10,2) NOT NULL
);

-- Credit Transactions table
CREATE TABLE credit_transactions (
  id UUID PRIMARY KEY,
  customer_id UUID NOT NULL REFERENCES customers(id),
  bill_id UUID REFERENCES bills(id),
  amount DECIMAL(10,2) NOT NULL,
  type TEXT NOT NULL,
  notes TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security (RLS)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies (users only see their own data)
CREATE POLICY "Users can manage their products" ON products FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their customers" ON customers FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their bills" ON bills FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their bill items" ON bill_items FOR ALL 
  USING (bill_id IN (SELECT id FROM bills WHERE user_id = auth.uid()));
CREATE POLICY "Users can manage credit transactions" ON credit_transactions FOR ALL 
  USING (customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid()));
```

### 5. Install Dependencies
```bash
flutter pub get
```

### 6. Run the App
```bash
# Android (emulator or device)
flutter run

# Debug mode
flutter run --debug

# Release APK
flutter build apk --release
```

---

## 📁 Project Structure
```
lib/
├── main.dart                    # App entry, Supabase init
├── core/
│   ├── constants/               # App config, routes, categories
│   ├── database/                # SQLite local DB (offline)
│   ├── models/                  # Product, Customer, Bill models
│   ├── router/                  # GoRouter navigation
│   ├── services/                # Supabase API service
│   └── theme/                   # Material 3 theme
├── features/
│   ├── auth/                    # Login, Signup, Splash
│   ├── dashboard/               # Home screen with stats
│   ├── inventory/               # Product CRUD
│   ├── billing/                 # Create bills, view history
│   ├── customers/               # Customer management + Udhar
│   ├── reports/                 # Analytics + charts
│   └── settings/                # Profile + app config
└── shared/
    └── widgets/                 # Reusable UI components
```

---

## ✨ Features
- 🔐 **Auth** — Supabase email/password auth
- 🏪 **Dashboard** — Live sales stats, low stock alerts
- 📦 **Inventory** — Full CRUD, categories, search
- 🧾 **Billing** — Cart, discount, GST, Cash/UPI/Udhar
- 👥 **Customers** — Udhar tracking, payment recording
- 📊 **Reports** — Bar charts, top products, revenue trends
- 📴 **Offline** — SQLite local DB, cloud sync when online

---

## 🛠 Tech Stack
| Layer | Technology |
|---|---|
| Framework | Flutter + Dart |
| Backend / Auth | Supabase |
| Local DB | SQLite (sqflite) |
| State | Riverpod |
| Navigation | GoRouter |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |
