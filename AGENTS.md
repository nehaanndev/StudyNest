- for all functions, make sure to write comments on what they do
- reuse existing functionality as far as possible. Look for existing functions to re-use before writing new ones
- Make sure no files are greater than 600 lines

## Git workflow

- Never commit directly to `main`
- All work goes on a feature branch: `git checkout -b feature/<short-description>`
- Open a PR into `main` when the feature is ready
- Branch naming: `feature/auth`, `feature/notes-editor`, `feature/custom-filters`, etc.