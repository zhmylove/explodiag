# Name

explodiag -- utility to parse SUNWexplo output archives

# Synopsis

```text
$ explodiag <explorer.SERIAL.HOSTNAME-DATE.tar.gz ...>
$ EXP_CLEANUP=1 EXP_EXTRACT=0 explodiag <extracted_explorer_dir ...>
```

# Description

The *explodiag* utility inspects SUNWexplo explorers for well-known errors and
presents the results in handsome form.  The utility architecture is built in a
module manner to simplify any functional improvements.  Please find tunable
parameters in a config file which location is specified inside *explodiag.pl*
as well as in environment variables (see below).

# Current limitations

When you specify explorer archives as a filenames, please consider using fully
qualified names like `explorer.12345678.hostname-2007.09.01.06.13.tar.gz` as the
script currently tries to extract hostname part from it.
`explorer_dir` is just a directory with extracted explorer and should be named
according to this scheme as well.

# Output formats

Explodiag supports three STDOUT output formats:
 - text - text-based tables
 - html - HTML page with systems status
 - dump - perl-friendly structures format

# Environment

| Name | Comment |
|-|-|
| EXP_OUTPUT | Output format (*html*, text, dump) |
| EXP_CLEANUP | Delete temporary files after parsing (*0* 1) |
| EXP_EXTRACT | Extract files before parsing (*1* 0) |
| _DEBUG | Debug level |

# Modules

Modules are any kind of scripts that checks single particular parts of
SUNWexplo output.  Each *module* takes hostnames as argv[] parameters.
Each module **must** write its status to the stdout in special format:
```text
HOSTNAME/SEVERITY/STATUS MESSAGE
```
Severity could be on of:

| Severity | Comment |
|-|-|
| ok | everything is ok, system does not need human check |
| warn | something went wrong |
| err | something is surely bad |
| messages | special severity for messages, they never works great |

Simple module could be written in such way:

```sh
#!/bin/sh

for HOST
do
  if out=`grep 'System Serial number' "$HOST/README" 2>/dev/null`
  then
    echo "$HOST/ok/$out"
  else
    echo "$HOST/err/no serial number found"
  fi
done
```

# Further work

I'll be pleased to accept your changes via pull requests.
