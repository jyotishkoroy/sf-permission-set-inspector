# Contributing

## Local development
```bash
sf org create scratch --definition-file config/project-scratch-def.json --set-default --alias psi
sf project deploy start --source-dir force-app --target-org psi
```

## Guidelines
- Keep changes covered with Apex tests.
- Avoid org-specific assumptions.
- Keep the project schema-neutral (no custom objects).
