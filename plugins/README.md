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

For repositories outside the shipped verified registry, the menu and interactive
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
Declarations are parsed as data. A failed entry makes the command fail.

```sh
plugin 'owner/my-plugin', tag: 'v0.1.0'
local_plugin '/absolute/path/my-plugin'
```

Installs validate names, files, script syntax, supported platforms and the minimum
Potions version, then scan scripts for dangerous patterns. Use `verify` for a
more detailed scan. `--skip-security` bypasses pattern scanning after review.
The scanner provides review assistance. Authors and users remain responsible
for the code's behavior. See [Security](SECURITY.md).

Managed GitHub installations record their exact Git commit in `Potionfile.lock`.
`status` checks the recorded commit and working tree. Shell startup loads active
configuration directly from the installed snapshot. Local files remain mutable.
The lock records provenance and selected refs. A tag can be moved upstream.

Failed installation hooks restore the previous managed plugin and its records.
Forced replacement keeps previous files under `plugins/.backups/`. Back up user
files inside hooks before changing them. External changes made by hooks require
the plugin's own recovery logic. Successful mutations regenerate shell loading.
Open a new shell to apply enable/disable changes to shell aliases and functions.

The CLI serializes mutations, recovers locks left by terminated processes, and
reports failures through its exit status. Local uninstall removes the link and
runs the optional uninstall hook. Its source directory is preserved.
