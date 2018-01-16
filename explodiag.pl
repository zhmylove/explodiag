#!/usr/bin/env perl
# made by: KorG

use strict;
use warnings;
use v5.8;

my $config_file = './explodiag.conf';
my $modules_dir = '~/explodiag/modules';

my $USAGE = "$0 <explorer.tar.gz ...>";

our %conf;
my $_DEBUG = 1;

sub debug {
   print STDERR @_, "\n" if $_DEBUG;
}

# Parse config file
unless (my $rc = do $config_file) {
   die "couldn't parse $config_file: $@" if $@;
   die "couldn't do $config_file: $!" unless defined $rc;
   die "couldn't run $config_file" unless $rc;
}

# Set default values
my %default_conf = (
   PREFIX => "/tmp",
   DEST => "explodiag",
   TAR => "gtar",
   CLEANUP => 0,
   RM_ARGS => "-rf"
);
defined $conf{$_} or $conf{$_} = $default_conf{$_} for keys %default_conf;

# Check @ARGV
die "Usage: $USAGE\n" unless @ARGV;

# Prepare temp directory
my $DIR = "$conf{PREFIX}/$conf{DEST}";
`rm $conf{RM_ARGS} "$DIR"` if -e $DIR;
die "$DIR: already exists!\n" if -e $DIR;

# Extract explorers to temp dir and chdir() there
mkdir "$DIR" or die $!;
for (@ARGV) {
   `$conf{TAR} -C "$DIR" -xf "$_"`;
   die "Error extracting $_" if $?;
}

# Chdir to destination directory
chdir "$DIR" or die $!;

# Rename extracted files to hostnames and fill @HOSTS
my @HOSTS;
for (@ARGV) {
# explorer.856eb306.db53-spb-2012.03.14.11.28.tar.gz
   s/.tar.gz$//;
   (my $to = $_) =~ s/^(?:[^.]*\.){2}(.*)-\d{4}\.\d\d\.\d\d\.\d\d\.\d\d$/$1/;
   debug "Renaming $_ to $to";
   rename "$_", "$to" or die $!;
   push @HOSTS, $to;
}

# Run modules
exit 0 unless @HOSTS;
for my $module (sort <$modules_dir/*>) {
   debug "Running $module...";
   print `"$module" @HOSTS`
}

END {
   # Remove temp directory
   chdir "/" or die $!;
   `rm $conf{RM_ARGS} "$conf{PREFIX}/$conf{DEST}/"` if $conf{CLEANUP}
}
