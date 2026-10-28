# HisaabMate Store Disclosure Notes

Use these notes when completing the Google Play Data Safety form and Apple privacy details for the local-first release.

## Data handled by the app

- Contacts: optional device access used to select people for ledger entries; not collected by the developer.
- Camera and photos: optional device access used for contact profile photos; not collected by the developer.
- Biometrics/device credentials: optional device authentication used for App Lock; authentication is handled by the operating system and biometric data is not collected by the developer.
- Financial records: user-entered ledger, expense, split, settlement, UPI ID, and contact data stored locally; not collected by the developer.
- Backups: created only when the user requests an export, encrypted by default with a user-provided password, and saved or shared through the operating system. Existing unencrypted backups can still be imported for compatibility.

## Current release does not include

- Account creation or login.
- Backend or cloud synchronization.
- Developer-operated cloud storage.
- Advertising or analytics.
- Payment processing.

## User-controlled external flows

- The user chooses where to save a backup with the system file picker.
- The user may share an encrypted backup with another app or person. The receiving destination still needs the user-provided password to restore it.
- UPI actions open external UPI applications; HisaabMate does not process payments.

The public policy is available at:

<https://sagarkalel.github.io/BorrowLedger/privacy-policy>
