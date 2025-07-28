# Crono Labs Toolkit (CLT)

> One toolkit to bind them all

Things provided by CLT:

- A home for tools and scripts written in either Bash or Python.
- A consistent CLI for accessing included tools and scripts.
- Baked in support to managing secrets.
- Easily installable.
- Free Coffee

## Dependencies

- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) >= 4
- [GNU sed](https://www.gnu.org/software/sed/) (Will be automatically installed if missing on macOS)
- [jq](https://jqlang.org/)
- [Python](https://www.python.org/) >= 3.12
- [UV](https://docs.astral.sh/uv/)
- [pre-commit](https://pre-commit.com/)
- [yq](https://github.com/mikefarah/yq)

## Installation

This will clone the project, build it and install it to your PATH:

```bash
git clone https://github.com/astercrono/cronolabs-toolkit.git && \
cd cronolabs-toolkit/bin && \
./clt install
```

Reload your shell.

Run `which clt` to confirm that it is installed.

## Usage

Run commands with the following syntax: `clt <command> [args]`

To view all available commands, run `clt list`.

To view the usage of a command, run `clt usage [command]`. Running this without an argument will show all commands.

Ex: `clt example` will run the example command:

```bash
$ clt example
Hello world!
```

## The User Dir

TODO

### Adding commands

TODO

### Provisioning

TODO

## Updating

To update source to the latest version, use the update command: `clt update`
