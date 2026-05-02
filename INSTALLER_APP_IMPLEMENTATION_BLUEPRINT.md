# Installer App Implementation Blueprint

## 1) Scope
Build a dedicated Android app for installer users.

Primary flow:
1. Installer login with installer ID
2. Select application ID from scheduled installations
3. Auto-fill and show readonly consumer details
4. Upload 7 mandatory photos with timestamp + GPS + installer identity
5. Admin verifies/rejects each photo
6. Rejected photo must be re-uploaded
7. After all 7 approved, admin marks installation complete

---

## 2) Screens (Installer App)

## A. Login Screen
Required:
- Fields: `installerId`, `password`
- Role gate: allow only installer users
- Store authenticated user session

Validation:
- Empty field checks
- Invalid credentials error
- Non-installer role blocked

Output:
- Navigate to `Application Selection Screen`

## B. Application Selection Screen
Required:
- Show only applications with stage:
  - `installationScheduled`
  - optionally assigned to logged-in installer (if assignment exists)
- Search by `application_number`, `consumer_name`, mobile
- Select one application

Output:
- Navigate to `Installation Stage Screen` with selected `applicationId`

## C. Installation Stage Screen
Sections:
1. Readonly Client Details
- Consumer Name
- Address
- Mobile Number
- AEN Office Name

2. Mandatory Photo Steps (exact order)
1. Site photo before installation
2. Structure installation photo
3. Solar panels installation photo
4. Electrical connection photo
5. Earthing installation photo
6. Inverter, ACDB, and DCDB photo
7. Final plant photo along with the client

3. Step Rules
- Step 1 enabled initially
- Step N enabled only if step N-1 is `approved`
- For rejected step: show rejected status + allow re-upload

4. Per Upload Metadata (auto captured)
- `captured_at` (device timestamp)
- `latitude`, `longitude` (live GPS)
- `captured_by_user_id`, `captured_by_user_name`

5. Upload Status
- On upload: status = `pending`
- Installer can see per-step status badge: `pending/approved/rejected`

---

## 3) Screens (Admin Panel)

## A. Installation Queue Screen
Required:
- List applications in:
  - `installationScheduled`
  - `installationCompleted` (for review/history)
- Open selected application to review photo steps

## B. Photo Verification Screen
Per photo:
- Preview image
- Show metadata: installer, captured time, GPS, remarks
- Actions:
  - `Approve`
  - `Reject` (remarks mandatory)

Rules:
- Only one active step progresses after previous approved
- After final (step 7) approved:
  - enable `Complete Installation` button

On Complete:
- Update application stage to `installationCompleted`
- Update installation record status to completed

---

## 4) API/Service Contracts

## Auth
- `loginInstaller(installerId, password) -> UserModel`
  - Validate role is installer

## Applications
- `fetchEligibleInstallationApplications() -> List<ApplicationModel>`
  - Filter by installation stage
  - Optional filter by assigned installer

## Installation
- `initializeInstallation(applicationId, applicationNumber, consumerName) -> InstallationModel`
- `fetchInstallationByApplicationId(applicationId) -> InstallationModel?`
- `updateInstallation(installation) -> InstallationModel`

## Photos
- `uploadInstallationPhoto(...) -> InstallationPhotoModel`
  - Input includes file, photoOrder, photoType, GPS, installer identity
  - Set verification status = `pending`
- `fetchInstallationPhotos(applicationId) -> List<InstallationPhotoModel>`
- `fetchPendingVerificationPhotos() -> List<InstallationPhotoModel>`
- `verifyPhoto(photoId, status, verifiedByUserId, verifiedByUserName, remarks?)`

## Stage Completion
- `updateApplicationStatus(applicationId, installationCompleted, stageStatus.completed, remarks)`

---

## 5) DB Fields Checklist

Table: `installation_photos`
- `id` (uuid, pk)
- `installation_id` (fk)
- `application_id` (fk)
- `application_number`
- `photo_order` (1..7)
- `photo_type`
- `storage_path`
- `photo_url`
- `latitude` (numeric)
- `longitude` (numeric)
- `captured_by_user_id`
- `captured_by_user_name`
- `captured_at` (timestamp)
- `verification_status` (`pending|approved|rejected`)
- `verification_remarks` (nullable, required when rejected)
- `verified_by_user_id`
- `verified_by_user_name`
- `verified_at` (timestamp)
- `created_at`
- `updated_at`

Recommended constraints:
- Unique: `(application_id, photo_order)`
- Check: `photo_order between 1 and 7`
- Check: valid `verification_status`

Optional assignment table:
- `installation_assignments(application_id, installer_user_id, assigned_at, assigned_by_user_id)`

---

## 6) Implementation Order (Execution Plan)

Phase 1: Installer App Access
1. Add installer-only login flow
2. Role guard and route protection
3. Session persistence

Phase 2: Application Selection
1. Build eligible applications API filter
2. Add list + search + select UI
3. Pass selected app into stage screen

Phase 3: Installation Stage Core
1. Readonly client detail card
2. 7-step photo cards
3. Step unlock logic by previous approved step
4. Camera + GPS capture integration
5. Upload API + pending status

Phase 4: Admin Verification
1. Admin queue listing
2. Photo review panel with metadata
3. Approve/reject action (reject reason mandatory)
4. Re-upload loop for rejected steps

Phase 5: Completion and Hardening
1. Enable complete installation only on all 7 approved
2. Stage transition to `installationCompleted`
3. Error/timeout/offline handling
4. Audit logs + activity trail

Phase 6: QA/UAT
1. End-to-end role tests (installer vs admin)
2. GPS permission denial flow
3. Rejection + re-upload regression test
4. Duplicate upload and race-condition checks

---

## 7) Acceptance Criteria (Must Pass)
1. Installer can login only with installer credentials.
2. Installer can select installation-scheduled application.
3. Client details auto-fill correctly and remain readonly.
4. All 7 mandatory photo steps are enforced.
5. Every upload stores timestamp + GPS + installer identity.
6. Uploaded photos appear as pending in admin verification.
7. Admin can approve/reject each photo.
8. Rejected photo blocks progression until re-upload and approval.
9. `Complete Installation` appears only after all 7 approvals.
10. On completion, application status becomes `Installation Completed`.
