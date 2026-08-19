# Code Style

## Terraform
- Format all `.tf` files with `terraform fmt` (enforced by pre-commit).
- Use **snake_case** for resource names, variables, locals, and outputs.
- Group related resources in dedicated files (`roles.tf`, `s3.tf`, etc.) rather than putting everything in `main.tf`.
- Keep `versions.tf` for provider and Terraform version constraints only.
- Use `locals` for computed values; prefer data sources over hardcoded ARNs.
- Pin module versions with pessimistic constraints (`~> X.Y`).
- Pin provider versions with minimum constraints (`>= X.Y`).

## Shell Scripts
- Start every script with `#!/bin/bash`.
- Keep `api_helpers/` scripts idempotent -- they run on every AFT apply.

## Jinja Templates
- Do not modify `aft-providers.jinja` or `backend.jinja` unless changing the AFT provider/backend contract. These are rendered by AFT at runtime.

## General
- Run `pre-commit run --all-files` (aliased as `mise run precommit`) before committing.
- No trailing whitespace; files must end with a newline.
