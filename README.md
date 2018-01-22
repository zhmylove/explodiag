# Name

explodiag -- utility to parse SUNWexplo output archives

# Synopsis

```text
$ explodiag <explorer.tar.gz ...>
$ EXP_CLEANUP=1 EXP_EXTRACT=0 explodiag <explorer_dir ...>
```

# Description

The *explodiag* utility inspects SUNWexplo explorers for well-known errors and presents the results in handsome form.
The utility architecture is built in a module manner to simplify any functional improvements. 
Please find tunable parameters in a config file which location is specified inside *explodiag.pl* as well as in environment variables (see below).

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
