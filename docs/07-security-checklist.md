## Secrets and credentials

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 1 | No API key, token or password is hardcoded in `lib/`, including in comments and commented-out code | **Yes** | The final project contains no hardcoded API keys, authentication tokens, passwords, or other private credentials. |
| 2 | Anything private is in a gitignored config or passed with `--dart-define`, with an example file committed | **N/A** | The application does not require private configuration, environment secrets, API credentials, or account-based services. |
| 3 | No keystore, `key.properties` or signing credential is in the repository | **N/A** | No private signing credentials are included in the repository. Any platform-specific signing files are kept outside version control. |
| 4 | Git history is clean: I searched `git log -p` for password, secret, api key and token | **Yes** | Git history was checked for common secret-related terms, and no credentials or sensitive values were found. |
| 5 | Any credential that was ever committed has been rotated | **N/A** | No credentials have been committed to the repository, so no credential rotation was necessary. |

## GitHub Actions

No GitHub Actions workflows are required for the final version of the project, so the workflow-specific checks are N/A.

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 6 | No secret value is written literally in any workflow YAML file | **N/A** | The project does not use GitHub Actions workflows. |
| 7 | Secrets are stored in repository Actions secrets and read with `${{ secrets.NAME }}` | **N/A** | The project does not require GitHub Actions secrets. |
| 8 | No workflow step echoes, dumps or debug-prints a secret, and I opened a recent run's log to confirm | **N/A** | No GitHub Actions workflows or related logs are used. |
| 9 | If I build a signed APK: the keystore is a base64 secret decoded to a file at build time, never printed | **N/A** | A signed APK is not built through a GitHub Actions workflow. |
| 10 | Uploaded build artifacts contain no key file, keystore or generated config | **N/A** | No GitHub Actions build artifacts are generated. |
| 11 | Third-party actions are pinned to a commit SHA, not a moveable tag | **N/A** | No third-party GitHub Actions are used. |
| 12 | Secret scanning and push protection are enabled on the repository | **Yes** | Repository security features are enabled to help detect and prevent accidental secret commits. |

## Backend and security rules

The application is fully local and does not use Firebase, Supabase, Firestore, Storage, or another online backend.

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 13 | Firestore and Storage rules are not left open to anyone; they require an authenticated user | **N/A** | No Firebase backend is used. |
| 14 | Rules restrict a user to their own documents where that makes sense | **N/A** | No online database or user documents are used. |
| 15 | If Supabase: Row Level Security is on for every table | **N/A** | Supabase is not used. |
| 16 | Firebase and Google API keys are restricted in the Google Cloud console to the APIs and app they are for | **N/A** | No Firebase or Google API credentials are required. |
| 17 | I opened the app signed out and confirmed I could not read or write data I should not | **N/A** | The game has no user accounts, authentication, or online data access. |
| 18 | Seed and sample data is invented, not real people's data | **Yes** | All player, item, seed, monster, farm, and statistics data are fictional game data created for the project. |

## Input and app surface

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 19 | Input is validated before it is written, not only styled as valid in the UI | **Yes** | User input is validated before it is stored or used by the game, preventing invalid values from being accepted as valid data. |
| 20 | Nothing secret is recoverable from the built app, since a shipped binary can be unpacked | **Yes** | The final build contains no API secrets, passwords, tokens, private keys, or other confidential credentials. |

## Repository and privacy

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 21 | No student number, personal email, phone number or home address in the repository or in commit messages | **Yes** | The repository contains no student numbers, personal contact information, or home addresses. |
| 22 | No classmate's personal data in the repository | **Yes** | No classmates' private or personally identifiable information is stored in the project. |
| 23 | Dependencies come from pub.dev, and `build/` and `.dart_tool/` are gitignored | **Yes** | Project dependencies are managed through `pubspec.yaml`, while generated files and build artifacts are excluded from version control. |
| 24 | Images, fonts and other assets are mine, licensed, or credited | **Yes** | Project assets are either created for the project, used under appropriate licensing, or credited in the project documentation. |
| 25 | Repository visibility is deliberate, and I checked it after my last push | **Yes** | Repository visibility and contents were reviewed before final submission to ensure that only intended project files are publicly accessible. |

## Anything I found and fixed

The security checklist confirmed that Eppy's Island does not depend on external accounts, private APIs, or a backend, which significantly reduces the amount of sensitive information that needs to be protected. I also ensured that credentials, personal information, generated files, and other private configuration are not included in the repository, while the game's saved data remains local to each player's device. Overall, the final project is designed to minimize the amount of sensitive data collected, stored, and exposed.
