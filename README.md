# Name

explodiag -- utility to parse SUNWexplo output archives

# Synopsis

```text
$ explodiag <explorer.tar.gz ...>
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
| EXP_OUTPUT | Output format |
| _DEBUG | Debug level |
