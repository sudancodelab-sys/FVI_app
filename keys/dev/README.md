# The keys of the first version (keys/dev)

Both apps of the first version use these keys (decision #49, 30 October 2026):
the institute wants the app locked and activated now, and secret production
keys in a later version. They are public: anyone can read them in this
repository.

| File | What it is |
|---|---|
| `content-root.hex` | The content root key: every level's key is derived from it (docs/REQUIREMENTS.md 5.4). |
| `issuer-seed.hex` | The seal (Ed25519) seed that signs activation codes. Its public key is in `apps/student/lib/src/activation/issuer.dart`; the admin app has both in `lib/src/data/secrets.dart`. |

Made with `dart run content_builder dev-keys`. An app built with them accepts
only codes signed with them: every code carries the id of the key that signed it.

For a later version, secret keys replace these: the student app takes the public
seal key with `--dart-define=FVI_ISSUER_KEY=...`, the content builder takes
`--keys` with the root key, and the admin app built with
`--dart-define=FVI_PRODUCTION=true` makes or restores its keys. Secret keys are
never committed (`keys/prod/` is in `.gitignore`). Students of the first version
then need new codes and the new app.
