# Publishing ExtraStats

The default branch is `main`. Forever releases use the existing CurseForge project
803163 and the repository secret `CURSEFORGE_TOKEN`.

## Build and review locally

Python 3.9+ is required; install `lupa==2.6` for the Lua smoke tests.

```sh
python tests/forever_settings_smoke.py
python tests/forever_controller_smoke.py
python tests/package_smoke.py
python scripts/package.py --version 0.1.0
```

The archive is `dist/ExtraStats-0.1.0.zip`, containing a single
`ExtraStats/` directory. It includes only the Forever runtime and release documentation, excluding
downloaded UI sources, worktrees, tests and build scripts. The source TOC is not modified.

## Publish Forever

Update CHANGELOG.md and smoke-test the package in the Forever client, including
settings, category ordering, controller focus, combat stats and spec gear swaps.
Commit and merge into main. Create and push an unused `forever-*` tag, for example:

```sh
git tag -a forever-0.1.0 -m "ExtraStats Forever beta"
git push origin main
git push origin forever-0.1.0
```

Tag push runs `forever-release.yml`: tests, packaging, GitHub artifact, and CurseForge
upload for 1.60.1 as a beta. A manual workflow run only builds a preview artifact;
it does not publish. Verify the existing token has access to project 803163.
Upload failures fail the workflow; check CurseForge before retrying an ambiguous
upload to avoid duplicate files. No credentials belong in this repository.

## Local publisher

The local `.env` is ignored by Git and excluded from packages. `.env.example`
documents the settings. The default project is 803163; uploads are Forever betas.
The API version is resolved exactly before uploading, and ambiguous uploads are
not retried automatically. Never print or commit the token.

```sh
python tools/publish.py --version 0.1.0 --changelog CHANGELOG.md --dry-run
python tools/publish.py --version 0.1.0 --changelog CHANGELOG.md --package-only
# This final command publishes to CurseForge:
python tools/publish.py --version 0.1.0 --changelog CHANGELOG.md
```

Use either the local publisher or the tag workflow for a given version, not both.
