# Contributing Guide

This project follows a professional Git workflow.

## Branch Naming

Use descriptive branch names:

```text
feat/backend-foundation
feat/frontend-foundation
feat/docker-backend
feat/song-upload
feat/audio-player
fix/auth-token-refresh
docs/update-readme
test/song-api
ci/github-actions
```

## Commit Message Style

Use conventional commit style:

```text
feat: add song model
fix: resolve upload validation bug
docs: update setup instructions
test: add song API tests
chore: configure project structure
ci: add backend test workflow
refactor: split Django settings
```

## Pull Request Workflow

1. Create a new branch from `main`
2. Make focused changes
3. Commit with a clear message
4. Push branch to GitHub
5. Open a pull request
6. Review the changes
7. Merge into `main`

## Code Quality

Planned quality tools:

- Backend linting with Ruff
- Backend tests with pytest
- Frontend linting with ESLint
- Frontend tests with Vitest
- Docker image scanning with Trivy
