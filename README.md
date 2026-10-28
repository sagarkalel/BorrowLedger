# HisaabMate

HisaabMate is a local-first Flutter app for tracking borrowing, lending,
personal expenses, group expenses, settlements, and contact-based ledger
records.

## What is included

- Dashboard summaries for lending, borrowing, expenses, and balances.
- Borrow/lend records with contacts, statuses, notes, and settlement actions.
- Personal and group expense tracking with split calculations.
- Contact details, optional UPI IDs, and optional contact profile photos.
- English, Hindi, and Marathi localization.
- Light, dark, and system theme modes.
- Optional app lock using device biometrics or device credentials, with a
  one-minute background timeout.
- SQLite storage on the device.
- Password-encrypted backup export and restore using the system file picker.
- Import compatibility for existing unencrypted `.blbackup`, `.zip`, and `.json`
  backups.

## Data and privacy

The current release requires no account and has no backend, analytics,
advertising, cloud sync, or developer-operated cloud storage. Records remain
on the device unless you explicitly export or share a backup. Contacts,
camera, and photo access are optional and are requested only for their related
features.

New backups are encrypted by default with a password. HisaabMate does not
store or recover the password, so a forgotten password cannot restore a
backup. Backups contain financial records, contact information, UPI IDs, and
profile photos. Sharing a backup gives the receiving app or person access to
the file, subject to their own policies.

App Lock is optional. Fingerprint, Face ID, PIN, pattern, and password checks
are handled by the operating system; HisaabMate does not collect or store
biometric data. The local SQLite database is protected by app-private device
storage but is not application-encrypted in this release.

Read the [Privacy Policy](https://sagarkalel.github.io/BorrowLedger/privacy-policy)
and [store disclosure notes](docs/STORE_DISCLOSURES.md).

## Project structure

```text
lib/
├── core/          # Constants, database helpers, services, theme, utilities
├── data/           # Models and repositories
└── presentation/   # Screens, widgets, Cubits, and localization
```

The app uses Flutter BLoC/Cubit for state management and SQLite repositories
for local persistence. The database schema and existing backup rows are kept
compatible across this release.

## Development setup

Requirements:

- Flutter SDK compatible with Dart `3.12.2` or newer compatible tooling.
- Android Studio and Android SDK for Android development.
- Xcode and CocoaPods for iOS development on macOS.

```bash
flutter pub get
flutter run
```

Useful checks and builds:

```bash
dart analyze
flutter test
flutter build appbundle --release
flutter build ios --release
```

The application version is maintained in `pubspec.yaml`. It is read from
installed package metadata at runtime; do not hardcode a second version in
application code or documentation.

## Permissions

- Contacts: optional, only when selecting or using contacts for ledger
  entries; the app does not modify device contacts.
- Camera: optional, only for taking a contact profile photo.
- Photos: optional, only for selecting a contact profile photo.
- Backup import/export: uses the system file picker and does not require broad
  storage permission.
- App Lock: optional device authentication; biometric data is handled by the
  operating system and is not collected by HisaabMate.

UPI actions hand off to an installed UPI application. HisaabMate does not
process or hold payments.

## Licensing

HisaabMate source code and original/generated project assets are licensed under
the [MIT License](LICENSE). The bundled Noto Sans Devanagari font is licensed
under the [SIL Open Font License 1.1](assets/fonts/OFL.txt). Flutter and other
dependencies retain their own licenses. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for attribution details.

## Support

For support or privacy questions, contact
[sagarkalel4141@gmail.com](mailto:sagarkalel4141@gmail.com).

Built with Flutter by Sagar Haridas Kalel.
