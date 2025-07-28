# Crono Labs Toolkit (CLT)

> One toolkit to bind them all

Things provided by CLT:

- A home for tools and scripts written in either Bash or Python.
- A consistent CLI for accessing included tools and scripts.
- Baked in support to managing sensitive configs via Mozilla SOPS.
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

## Development

These notes are for understanding the project structure and how to contribute.

### Structure

The clt project is a Python project that supports both Bash and Python commands.

The folder structure:

- `bin/` - Bash scripts
- `bin/command/` - Bash commands
- `bin/lib/` - Supporting Bash functions
- `resource/` - Where to put any supporting resource files
- `src/` - Python code
- `src/clt/` - Python commands and supporting libraries
- `tests/` - Python unit tests

The launching point of the application is `bin/clt`. If the installation steps were followed, then this script will be
globally available on your PATH. This is a Bash script that will bootstrap the execution of both Bash and Python
commands.

**Bash Commands vs Python Commands:**

- If a command is a Bash script, then its source should be under `bin/command` and named with a `app-<command>.sh` convention.
- If a script is a Python module, then its source should be under `src/clt` and named with a `<command>.py` convention.

When a command is executed, a corresponding Bash script will be attempted first. If the Bash script is not found, then
the corresponding Python module will be searched for. It is important the above mentioned naming conventions are
followed so that the correct file can be located for a command.

### Adding a new command

**NOTICE: This section is out-of-date**

Let's say we want to add a new command called `foo` that prints out the message `bar`.

First add the command to `resource/commands.yaml`:

```yaml
commands:
  list:
    description: Show list of available commands
  location:
    description: Print installation path
  install:
    description: Build and add project to PATH
  ...
  foo:
    description: Print the message 'bar' # Our new command

```

Now let's create the command.

**If using Bash:**

Create new file: `bin/command/app-foo.sh` with contents:

```bash
echo "bar"
```

**If using Python:**

Create new file: `src/clt/foo.py` with contents:

```
print("bar")
```

**Running:**

Regardless of whether the command is implemented with Bash or Python, the execution is the same:

```Bash
$ clt foo
bar
```

## Updating

To update source to the latest version, use the update command: `clt update`
