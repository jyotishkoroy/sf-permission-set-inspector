# sf-permission-set-inspector

**Permission Set Inspector** — pick a user and view assigned Permission Sets / Group memberships, plus a quick diff between two users.

- **Repo name:** `sf-permission-set-inspector`
- **Description:** Read-only admin utility: permission set assignments + permission set group memberships, with user-to-user diff.
- **License:** MIT (c) 2026 Jyotishko Roy — https://orcid.org/0009-0000-2837-4731

---

## Features
- Typeahead user picker (fast in large orgs)
- Direct Permission Set assignments
- Permission Set Group memberships
- Optional “expand groups” to list included Permission Sets (when accessible)
- Quick diff:
  - Permission Sets: only A / only B / both
  - Groups: only A / only B / both

---

## Install

### Deploy
```bash
sf org login web --set-default --alias psi
sf project deploy start --source-dir force-app --target-org psi
```

### Post-deploy
1. Assign permission set **Permission Set Inspector**
2. App Launcher → **Permission Set Inspector**
3. Open tab **Permission Set Inspector**

---

## Permissions
This is an admin-focused tool. The permission set grants:
- API Enabled
- View Setup
- View All Users

Some orgs restrict setup objects related to Permission Set Groups.
If group expansion is not available, the app will still show group memberships.

---

## Repository layout
- `force-app/main/default/lwc/psiApp` — main UI
- `force-app/main/default/lwc/psiUserPicker` — reusable user typeahead picker
- `force-app/main/default/lwc/psiSnapshotPanel` — snapshot display component
- `force-app/main/default/classes/PSI_AppController.cls` — read-only aggregation services

---

## Maintainer
**Jyotishko Roy** — ORCID: https://orcid.org/0009-0000-2837-4731

---

## License
MIT
