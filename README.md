```
flutter pub get
dart run flutter_launcher_icons
```

# 💰 BorrowLedger - Complete Finance Tracking App

A comprehensive Flutter application for managing personal finances, tracking borrowing/lending, expenses, and split bills with friends.

## ✨ Features

### 📊 Dashboard

- Real-time financial summary
- Total lent/borrowed overview
- Net balance calculation
- Recent transactions display
- Pull-to-refresh functionality

### 💸 Borrow & Lend Management

- Track money you've lent to others
- Record money you've borrowed
- Mark transactions as paid/pending
- Search and filter by contact or status
- Transaction history with details

### 🧾 Expense Tracking

- Categorized expense tracking
- 10 pre-defined categories (Food, Transport, Shopping, etc.)
- Monthly/yearly expense summaries
- Category-wise spending analysis
- Search and filter expenses

### 🍕 Split Expenses

- Create split expenses with multiple people
- Equal split calculation
- Track who paid and who owes
- Monitor settlement status
- Detailed participant breakdown

### 👥 Contact Management

- Store contact information (name, phone, email)
- View transaction history per contact
- Easy add/edit/delete functionality
- Search contacts

### ⚙️ Settings

- Light/Dark theme toggle
- System default theme option
- Export data (backup)
- Import data (restore)
- Clear all data option
- App version and about info

## 🏗️ Architecture

### Clean Architecture Pattern

```
lib/
├── core/
│   ├── constants/      # App-wide constants
│   └── theme/          # Theme configuration
├── data/
│   ├── database/       # SQLite database helper
│   ├── models/         # Data models
│   └── repositories/   # Data access layer
└── presentation/
    ├── cubit/          # State management (BLoC pattern)
    ├── screens/        # UI screens
    └── widgets/        # Reusable widgets
```

### State Management

- **BLoC/Cubit Pattern** for predictable state management
- Separate cubits for each feature:
  - `DashboardCubit` - Dashboard data
  - `TransactionCubit` - Borrow/lend operations
  - `ExpenseCubit` - Expense tracking
  - `SplitCubit` - Split expense management
  - `ContactCubit` - Contact operations

### Database Schema

**Contacts Table**

- id (PRIMARY KEY)
- name
- phone
- email
- created_at, updated_at

**Transactions Table**

- id (PRIMARY KEY)
- type (borrow/lend)
- contact_id (FOREIGN KEY)
- amount
- description
- date
- status (pending/paid/partial)
- created_at, updated_at

**Expenses Table**

- id (PRIMARY KEY)
- amount
- category
- description
- date
- created_at, updated_at

**Split Expenses Table**

- id (PRIMARY KEY)
- title
- total_amount
- paid_by_user
- description
- date
- status (pending/settled)
- created_at, updated_at

**Split Participants Table**

- id (PRIMARY KEY)
- split_id (FOREIGN KEY)
- contact_id (FOREIGN KEY)
- share_amount
- paid
- status (pending/paid)

## 🎨 Design Features

### Theme System

- **Primary Colors**: Green (#8BC34A) & Blue (#4A90C3) from logo
- Material 3 design system
- Comprehensive light and dark themes
- Smooth theme transitions

### UI Components

- Animated splash screen
- Bottom navigation (5 tabs)
- Floating action button with quick-add menu
- Search bars with real-time filtering
- Filter chips for easy categorization
- Card-based layouts
- Modal bottom sheets for details
- Empty states with helpful messages
- Loading indicators
- Pull-to-refresh

### Animations

- Splash screen fade and scale animations
- Smooth page transitions
- Ripple effects on tap
- Loading states

## 📦 Dependencies

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Database
  sqflite: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.1

  # Internationalization & Date
  intl: ^0.18.1

  # UI
  cupertino_icons: ^1.0.6
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK / iOS SDK

### Installation

1. **Clone the repository**

```bash
git clone <your-repo-url>
cd borrow_ledger
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Run the app**

```bash
flutter run
```

### Build for Production

**Android APK**

```bash
flutter build apk --release
```

**Android App Bundle**

```bash
flutter build appbundle --release
```

**iOS**

```bash
flutter build ios --release
```

## 📱 Screens Overview

1. **Splash Screen** - Animated logo with brand colors
2. **Dashboard** - Financial summary and recent transactions
3. **Borrow/Lend Screen** - Manage all lending and borrowing
4. **Add Transaction** - Form to add/edit borrow/lend records
5. **Splits Screen** - Manage shared expenses
6. **Add Split** - Create new split expense with participants
7. **Expenses Screen** - Track personal expenses
8. **Add Expense** - Form to add/edit expenses
9. **Contacts Screen** - Manage all contacts
10. **Add Contact** - Form to add/edit contact details
11. **Settings Screen** - App settings and preferences

## 🔐 Data Privacy

- All data stored locally using SQLite
- No external servers or cloud sync
- Export/import functionality for backups
- User has full control over their data

## 🎯 Future Enhancements

- [ ] Charts and graphs for expense analysis
- [ ] Recurring transactions
- [ ] Reminders for pending payments
- [ ] Currency support (multi-currency)
- [ ] Cloud backup and sync
- [ ] Receipt/bill photo attachment
- [ ] Reports generation (PDF/Excel)
- [ ] Budget planning
- [ ] Expense predictions using ML
- [ ] Multi-language support

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer

Built with ❤️ using Flutter

## 📞 Support

For support, email your-email@example.com or create an issue in the repository.

---

**Version:** 1.0.0  
**Last Updated:** December 2024
