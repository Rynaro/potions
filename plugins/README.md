# Potions plugins

Use `potions plugin` to open the terminal menu. The same operations work from
the command line and from an installed copy of Potions.

```sh
potions plugin install owner/my-plugin@v0.1.0
potions plugin list
potions plugin info my-plugin
potions plugin deactivate my-plugin
potions plugin activate my-plugin
potions plugin update my-plugin
potions plugin uninstall my-plugin
```

GitHub shorthand, `https://github.com/owner/repo.git`, and the legacy
`'owner/repo, tag: v0.1.0'` or `'owner/repo, branch: main'` forms are accepted.
`@v0.1.0` selects a tag. Updates retain the selected tag or branch and preserve
an inactive plugin's state. Repository names beginning with `potions-` retain
the historical installed name without that prefix. `list` shows installed names.

For repositories outside the shipped maintainer allowlist, the menu and interactive
CLI display the exact fetched commit and ask whether to trust its code. In scripts,
review the repository and pass `--trust` explicitly. This also applies to updates.

```sh
potions plugin install owner/my-plugin@v0.1.0 --trust
potions plugin install ./my-plugin
potions plugin install 'owner/my-plugin, branch: main' --trust
```

Local paths start with `./`, `../`, `/` or `~`. Local installs link directly to the
working directory. Edit the files and open a new shell to load active configuration.
Plugin scripts and shell configuration execute with your account permissions.

Create a plugin in your current directory.

```sh
potions plugin create my-plugin
potions plugin validate ./my-plugin
potions plugin install ./my-plugin
```

The scaffold contains a manifest, README and `config/init.zsh`. Add `install.sh`
only when setup needs commands. Edit the manifest and shell configuration, commit the directory
to a GitHub repository, and tag a release. `--potion` selects the supported YAML
manifest instead of JSON. See [Creating plugins](CREATING_PLUGINS.md).

`potions plugin install` reads `~/.potions/Potionfile` (or `$POTIONS_HOME/Potionfile`).
Create it from the installed template, preserving any existing declarations,
then edit the file.

```sh
cp -n "${POTIONS_HOME:-$HOME/.potions}/Potionfile.template" "${POTIONS_HOME:-$HOME/.potions}/Potionfile"
```

Declarations are parsed as data. The interactive command asks for trust for each
remote source that needs approval. A failed entry makes the command fail while
successful entries remain installed and available in new shells.

```sh
plugin 'plugin-hello-world'
local_plugin './my-plugin'
```

Relative local paths resolve from the Potionfile's directory. Existing paths
relative to the calling directory are accepted with a migration message when
there is no matching path beside the Potionfile. Prefer an absolute path or a
Potionfile-relative path for reproducible use. `~/` uses your home directory.

After reviewing every declared remote source, scripted installs can use
`potions plugin install --trust`. The existing `--force` and `--skip-security`
options also apply to every declared entry. Use `--force` deliberately when
replacing an existing source.

Installs validate names, files, script syntax, supported platforms and the minimum
Potions version, then scan scripts for dangerous patterns. Use `verify` for a
more detailed scan. `--skip-security` bypasses pattern scanning after review.
The scanner provides review assistance. Authors and users remain responsible
for the code's behavior. See [Security](SECURITY.md).

Managed GitHub installations record their exact Git commit in `Potionfile.lock`.
`status` checks the recorded commit and working tree. Shell startup loads active
configuration directly from the installed snapshot. Local files remain mutable.
The lock records provenance and selected refs. A tag can be moved upstream.

From Potions 2.18.1, installing by Shelf name requires a fresh catalog response
and a `reviewed_commit` in its entry. Potions checks the fetched Git revision
against that value before running hooks. The source and review revision must
also agree with the published index. These checks apply with `--trust` or
`--skip-security`. A mismatched revision, missing review record, unavailable
catalog or removed listing stops the operation and preserves the current plugin.
Updates of a registry installation resolve its Shelf name again and retain its
enabled or disabled state. The lockfile records its source as `registry:NAME`.

Potions 2.18.0 used `github:` provenance for every remote installation, so its
lockfile cannot identify which ones originally came from the Shelf. After
upgrading, use `potions plugin install NAME --force` to explicitly replace an
old installation with the reviewed catalog version. The current disabled state
is preserved. Existing direct GitHub sources keep their previous update behavior.

Failed installation hooks restore the previous managed plugin and its records.
Forced replacement keeps previous files under `plugins/.backups/`. Back up user
files inside hooks before changing them. External changes made by hooks require
the plugin's own recovery logic. Successful mutations regenerate shell loading.
Open a new shell to apply enable/disable changes to shell aliases and functions.

The CLI serializes mutations, recovers locks left by terminated processes, and
reports failures through its exit status. Local uninstall removes the link and
runs the optional uninstall hook. Its source directory is preserved.
