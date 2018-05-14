# reviewboard-cli

Set of bash scripts implementing a Command Line Interface for ReviewBoard.
Code review over a web browser might be bothering some time: lack of performance, lack of properly configured linter and usual tools, make code painful to read.
This repository aims at providing the bare minimum for local code download and patch file creation with comments integration.
The utilities are fine tuned for vim & tmux use. More to come.

# INSTALL
Make sure you have the following apps installed:
- `sudo apt-get install jq # JSON parser`
- `sudo apt-get install merge`
- `sudo apt-get curl`

Create or update the reviewboardrc file located at:

`$HOME/.reviewboardrc`

With the following content:

`REVIEWBOARD_URL="https://reviewboard.yourdomain.com/"`

# HOWTO

## View old and new files

Simply call:
`$ ./getlastdiff.sh CHANGENUM`

This will generate the file hierarchy in a temp directory.
Then you can generate the vim command via:
`$ ./applylocaldiff.sh GENERATED_DIR`

## View by applying patch on local source base

ReviewBoard API might generate extra stub path that is not included in your code base hierarchy. ie:
`//branch/project/src`

Whereas your local hierarchy is:
`project/src`

If you hit that issue, simply call "getlastdiff" with an extra argument:
`$ ./getlastdiff.sh CHANGENUM project`

This will make sure the generated patch files are located under project/ instead of /branch/project.

From there, simply apply
`$ applysandboxdiff.sh GENERATED_DIR`

# Comments
Comments are added directly into the new/patch file

# SUPPORTED EDITOR
vim only, for now. Feel free to update the "apply\*" scripts for your preferred editor.

# What tech is used behind?
[RB WebAPI](https://www.reviewboard.org/docs/manual/1.5/webapi/)
