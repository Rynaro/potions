# Creating a plugin

Run `potions plugin create my-plugin` in the directory where you keep projects.
Use `--potion` to generate `.potion` YAML. The default is `plugin.potions.json`.

The required manifest fields are `name`, `version`, `description`, `author` and
`potions_min_version`. Names contain letters, digits, underscores and hyphens,
starting with a letter or digit. Optional `platforms` restricts support to exact
`macos`, `linux`, `wsl` and `termux` identifiers. Native Fedora uses `linux`.
Omitting platforms supports every platform.

Add aliases, functions and shell settings to `config/*.zsh` or `config/*.sh`.
Potions sources these files when a new shell starts and the plugin is active.
A shell-only plugin needs just a manifest and shell configuration. The scaffold
also generates a README for sharing.

Optional `install.sh`, `uninstall.sh`, `activate.sh` and `deactivate.sh` hooks
run in the plugin directory through Bash with `set -eo pipefail`. When present, `install.sh` must be executable. README is optional for installation. The environment provides
`POTIONS_HOME`. Keep setup idempotent, quote paths, detect the platform before
installing packages, and back up user files before changing them. Return a
nonzero exit code when a hook fails.

Validate and test locally.

```sh
potions plugin validate ./my-plugin
potions plugin verify ./my-plugin
potions plugin install ./my-plugin
potions plugin deactivate my-plugin
potions plugin activate my-plugin
potions plugin uninstall my-plugin
```

The local install links to the project, so changes are available in new shells.
Uninstall preserves the project files. Hook changes to other user files require
your own backup and recovery logic.

Publish the directory as a GitHub repository and tag a release, for example
`v0.1.0`. Document supported platforms, setup changes and how users recover them.
Users can then run `potions plugin install owner/my-plugin@v0.1.0` and review
the repository/revision in the trust prompt. Scripted installs require `--trust`.

For discovery by name, submit the published revision to Potions Shelf using its
entry helper and include the generated index in your pull request. The Shelf
checks the public revision and inspects its files before maintainers review the
listing. Report suspicious listed packages through its security policy.
[Shelf contribution guide](https://github.com/Rynaro/potions-shelf/blob/main/CONTRIBUTING.md)

Repositories may contain ordinary nested files. Symlinks within a plugin are
rejected to keep validation and loading within its directory. Avoid vendoring
secrets. GitHub installs preserve a Git snapshot, and `status` reports local
changes against its recorded revision.
