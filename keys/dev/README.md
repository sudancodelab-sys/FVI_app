# DEVELOPMENT KEYS: never for production

These keys are public: anyone can read them in this repository. They exist so
the student app can be built, encrypted and activated while it is developed
and tested, before the admin app and the production keys exist.

| File | What it is |
|---|---|
| `content-root.hex` | The content root key: every level's key is derived from it (docs/REQUIREMENTS.md 5.4). |
| `issuer-seed.hex` | The seal (Ed25519) seed that signs activation codes. Its public key is in `apps/student/lib/src/activation/issuer.dart`. |

Made with `dart run content_builder dev-keys`. An app built with them accepts
only codes signed with them, and a production app rejects them: every code
carries the id of the key that signed it.

Production keys are made in the admin app, kept in its password-protected
backup and in GitHub's encrypted secrets, and are never committed
(`keys/prod/` is in `.gitignore`). Who makes them and where their backup is kept
is open question 2 in docs/REQUIREMENTS.md section 10.
