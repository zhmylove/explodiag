#!/usr/bin/env perl
# made by: KorG

use strict;
use warnings;
use v5.8;

my $config_file = './explodiag.conf';
my $modules_dir = '~/explodiag/modules';
my $_DEBUG      = 1;

my $USAGE = "$0 <explorer.tar.gz ...>";

our %conf;
my @HOSTS;
my %result;
my %modules;

#TODO
# force rm / interactive rm and avoid bumblebee issue #123
# gtar/tar autodetect

# Print debug output
sub debug { print STDERR @_, "\n" if $_DEBUG; }

# Parse config file
unless (my $rc = do $config_file) {
   die "couldn't parse $config_file: $@" if $@;
   die "couldn't do $config_file: $!" unless defined $rc;
   die "couldn't run $config_file" unless $rc;
}

# Set default values
my %default_conf = (
   PREFIX  => "/tmp",
   DEST    => "explodiag",
   TAR     => "gtar",
   CLEANUP => 0,
   RM_ARGS => "-rf",
   OUTPUT  => "text",
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
for (@ARGV) {
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
   for (split /\n/, `"$module" @HOSTS`) {
      my ($host, $code, $text) = split /\//;
      my $module_name = (split /\//, $module)[-1];
      $modules{$module_name} = 1;
      push @{ $result{$host}->{$module_name} }, [ $code, $text ];
   }
}

# Format output
if ($conf{OUTPUT} =~ /^te?xt$/i) {
   for my $module_name (sort keys %modules) {
      print " === $module_name === \n";
      local $" = " | ";
      for (sort keys %result) {
         printf "%16s\n", $_;
         print " " x 16 . "@$_" . "\n" for @{ $result{$_}->{$module_name} };
      }
   }
} elsif ($conf{OUTPUT} =~ /^dump$/i) {
   require Data::Dumper;
   local $Data::Dumper::Purity = 1;
   print Data::Dumper->Dump([\%result], ["explodiag"]);
} elsif ($conf{OUTPUT} =~ /^html?$/i) {
   # TODO
} else {
   die "Unknown output format: $conf{OUTPUT}\n";
}

END {
   # Remove temp directory
   chdir "/" or die $!;
   `rm $conf{RM_ARGS} "$conf{PREFIX}/$conf{DEST}/"` if $conf{CLEANUP}
}
