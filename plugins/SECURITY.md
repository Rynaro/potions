# Plugin security

Plugins execute Bash setup hooks and source active shell configuration with the
user's permissions. Review repository code before trusting an installation.

GitHub sources accept HTTPS GitHub URLs or `owner/repo`, with validated names and
refs. Remote installs resolve an exact commit before asking for trust. Scripted
installs of unverified repositories require `--trust`. Registry membership uses
the full repository identity. Short-name matches cannot authorize another owner. The shipped allowlist is
currently empty. A full repository entry authorizes all of its fetched revisions,
and its legacy version/checksum columns provide no additional enforcement.

Validation rejects invalid names, missing files, unsupported platforms, syntax
errors in known scripts and symlinks in plugin contents. Pattern scans flag some
dangerous shell commands. They cannot establish that arbitrary code is safe.
`--skip-security` bypasses the pattern scan and leaves validation enabled.

Shelf installations in Potions 2.18.1 require a fresh active entry with a
`reviewed_commit`. Before any hook runs, the fetched Git HEAD must equal that
40-character revision. The canonical manifest source and revision must agree
with the published index. `--trust` and `--skip-security` do not bypass these checks.
Updates retain the Shelf name as their source and recheck the current entry.
Unreachable catalogs, removed entries, missing review revisions and moved tags
stop installation or update. Shelf screening is best effort, and users still
review and approve the code they run.

Direct GitHub and local installs are outside Shelf screening. Their publishers
are responsible for their code and support. Older Potions versions recorded all
remote sources as `github:`, so those installs keep their direct-source behavior
until the user explicitly adopts the reviewed path with
`potions plugin install NAME --force` after upgrading.

Report every suspicious listed package through the
[Shelf security reporting process](https://github.com/Rynaro/potions-shelf/security/policy).
Use its private reporting link for sensitive findings and keep credentials and
private files out of public issues.

`Potionfile.lock` records the selected source/ref and resolved Git commit.
`potions plugin status` checks the installed Git commit and local modifications.
Shell startup loads configuration directly. Local installs link to mutable author
files. Repository refs, including tags, can change on a later update.

Managed replacements retain a backup of previous plugin files. Installation hook
failure restores the previous files, state and lock entry. A hook's changes to
external user files require its own backups and recovery. Plugin authors must
protect user data and keep hooks idempotent.
