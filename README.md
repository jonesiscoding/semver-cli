# SemVer CLI

A command-line tool designed to parse, increment, and format semantic version numbers. It supports
various input methods such as direct input, reading versions from macOS or macOS app bundles, and Git tags. The output
can be formatted in plain text, JSON, or YAML.

## Requirements

The utility will run in most Bash environments, including macOS.

* For filtering or JSON output: `jq` (https://github.com/jqlang/jq)
* For YAML output: `yq` is required (https://github.com/mikefarah/yq)

## Usage

When used without any flags, the version number given will be parsed and displayed with the individual major, minor, 
revision, build, and pre-release portions, as well as any extra data, the full version number, and raw input.

### Version Formatting

The formatting of the version number output can be controlled with the `--format` flag and various tokens.  When using
the lowercase versions of tokens, the preceding separator will be automatically removed if that token's part is empty.

The default format is `%M.%N.%r`, which will display the major and minor version, as well as the revision if present.

| Token | Use                                                                   |
|-------|-----------------------------------------------------------------------|
| `%M`  | Major Version                                                         |
| `%N`  | Minor Version                                                         |
| `%R`  | Revision/Patch                                                        |
| `%P`  | Pre-Release                                                           |
| `%B`  | Build                                                                 |
| `%n`  | Minor Version<br/>Consumes preceding `.` if minor version not present |
| `%r`  | Revision/Patch<br/>Consumes preceding `.` if revison not present or 0 |
| `%p`  | Pre-Release<br/>Consumes preceding `-` if pre-release not present     |
| `%b`  | Build<br/>Consumes preceeding `+` if build not present                |

### Version Incrementing

The version number can be incremented with three flags, which can be combined to further increment the version.  

When incrementing the major version, the minor and revision numbers will be reset. When incrementing the minor version, the 
revision will be reset.  Combining flags will increment the subsequent corresponding part _after_ the reset.

- Increment Major:
  ```bash
  semver 1.2.3 --major --quiet
  # Result: 2.0
  ```
- Increment Minor:
  ```bash
  ./semver 1.2.3 --minor --quiet
  # Result 1.3
  ```
- Increment Patch/Revision:
  ```bash
  ./semver 1.2.3 --patch
  # Result 1.2.4
  ```
- Combined Example:
  ```bash
  ./semver 1.2.3 --major --patch
  # Result 2.0.1
  ```

### Version Source Options & Arguments

The version can be given as a literal argument.  Alternatively, you can give a path to a macOS app bundle, or use one of
the flags below to gather the version from macOS or Git repo tags.

- **Use macOS OS version**:
  ```bash
  ./semver --os
  ```

- **Use Git tags for input version**:
  ```bash
  ./semver --git
  ```

### Output Options

- **Output Only Version**:
  ```bash
  ./semver --git --quiet
  # Displays only the version number derived from Git tags
  ```

- **Display a Single Part**:
  ```bash
  ./semver 1.2.3 '.major'
  ```

- **Output as JSON**:
  ```bash
  ./semver 1.2.3 --json
  ```

- **Output as YAML**:
  ```bash
  ./semver 1.2.3 --yaml
  ```

## Exit Codes

- `0`: Success
- `1`: Error
- `2`: Invalid Option
- `3`: Missing JQ
- `4`: Missing YQ; used `--yaml` flag
- `5`: Missing Git; used `--git` flag
- `10`: Not in Git Repo; used `--git` flag

## License

This script is licensed under the Apache License, Version 2.0. For more details, please refer to the LICENSE and
NOTICE files in the repository.
