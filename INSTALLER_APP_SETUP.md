# DoonInfra Installer App (Separate Android App)

This creates a separate Android app APK for installer operations, while staying connected to the same CRM/Supabase backend.

## Build/Run Commands

Run on device/emulator:

```powershell
flutter run --flavor installer -t lib/main_installer.dart
```

Build APK:

```powershell
flutter build apk --flavor installer -t lib/main_installer.dart
```

Output APK:

`build/app/outputs/flutter-apk/app-installer-release.apk`

## What This App Includes

- Installer login (same backend users table)
- Installation access permission check (`installation_access`)
- Installation workflow screen
- Client selection + readonly details
- 7 mandatory photo stages
- Geo-tag + timestamp + installer identity capture

## CRM Link (Admin)

Admin continues to use the main CRM app/dashboard for:

- Reviewing uploaded photos
- Approve/Reject
- Final installation completion

No separate backend is required. Both apps use the same Supabase project and tables.

## One-time DB Fix (if approve/reject or upload behaves inconsistently)

If you previously had duplicate rows for the same stage, run this once in Supabase SQL Editor:

```sql
delete from public.installation_photos a
using public.installation_photos b
where a.id <> b.id
  and a.application_id = b.application_id
  and a.photo_order = b.photo_order
  and a.updated_at < b.updated_at;
```

Then ensure unique constraint exists:

```sql
alter table public.installation_photos
  add constraint installation_photos_application_stage_unique
  unique (application_id, photo_order);
```
