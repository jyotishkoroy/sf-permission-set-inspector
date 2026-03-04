# Architecture

## Data sources (read-only)
- `User` (profile, last login, active status)
- `PermissionSetAssignment` (direct Permission Set assignments)
- `PermissionSetGroupAssignment` (Permission Set Group memberships)
- Optional: `PermissionSetGroupComponent` (expand groups to included Permission Sets)

## Design notes
- The UI uses a typeahead user picker to avoid loading all users.
- Diff is computed server-side for consistent results and smaller payloads.
- No persistence. The app does not write org data.
