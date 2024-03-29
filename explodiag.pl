#!/usr/bin/env perl
# made by: KorG

use strict;
use warnings;
use v5.8;
use FindBin;

chdir $FindBin::Bin or die $!;

my $config_file = './explodiag.conf';
my $modules_dir = './modules';
my $_DEBUG      = 0;

my $USAGE = "$0 <explorer.tar.gz ...>";

our %conf;   # configuration hash
my @HOSTS;   # hosts array
my %result;  # module execution results
my %modules; # module names
my %total;   # host total status hash
my %summary; # host / module statistics

#TODO
# force rm / interactive rm and avoid bumblebee issue #123
# gtar/tar autodetect

# Print debug output
sub debug { print STDERR @_, "\n" if $_DEBUG; }
$_DEBUG = int $ENV{_DEBUG} if defined $ENV{_DEBUG};

# Parse config file
unless (my $rc = do $config_file) {
   die "couldn't parse $config_file: $@" if $@;
   die "couldn't do $config_file: $!" unless defined $rc;
   die "couldn't run $config_file" unless $rc;
}

# Set default values
my %default_conf = (
   PREFIX  => "/var/tmp",
   DEST    => "explodiag",
   EXTRACT => 1,
   TAR     => "gtar",
   CLEANUP => 0,
   RM_ARGS => "-rf",
   OUTPUT  => "html",
);
defined $conf{$_} or $conf{$_} = $default_conf{$_} for keys %default_conf;

# Get some values from the environment
$conf{OUTPUT} = $ENV{EXP_OUTPUT} if defined $ENV{EXP_OUTPUT};
$conf{CLEANUP} = $ENV{EXP_CLEANUP} if defined $ENV{EXP_CLEANUP};
$conf{EXTRACT} = $ENV{EXP_EXTRACT} if defined $ENV{EXP_EXTRACT};

# Check @ARGV
die "Usage: $USAGE\n" unless @ARGV;

# Prepare temp directory
my $DIR = "$conf{PREFIX}/$conf{DEST}/";
`rm $conf{RM_ARGS} "$DIR"` if -e $DIR;
die "$DIR: already exists!\n" if -e $DIR;

# Extract explorers to temp dir and chdir() there
mkdir $DIR or die $!;
for (@ARGV) {
   if ($conf{EXTRACT}) {
      `$conf{TAR} -C "$DIR" -xf "$_"`;
      die "Error extracting $_" if $?;
   } else {
      `ln -s "$_" "$DIR"`;
      die "Error linking $_" if $?;
   }
}

# Chdir to destination directory
chdir $DIR or die $!;

# Rename extracted files to hostnames and fill @HOSTS
for (@ARGV) {
   s/.tar.gz$//;
   s/\/$//;
   s/.*\///;
   my $to = $_;

   if ($to =~ s/^(?:[^.]*\.){2}(.*)-\d{4}\.\d\d\.\d\d\.\d\d\.\d\d$/$1/) {
      # We're dealing with fully qualified explorer name
      debug "Renaming $_ to $to";
      $_ ne $to and (rename $_, $to or die $!);
   } else {
      # Looks like the name is not in a proper format
      die 'You must specify explorer name in a proper format, either a file' .
      'explorer.12345678.hostname-2007.09.01.06.13.tar.gz, or a directory' .
      'explorer.12345678.hostname-2007.09.01.06.13/';
   }

   push @HOSTS, $to;
}

# Run modules
exit 0 unless @HOSTS;
for my $module (sort {
      my ($c, $d) = ($a =~ /(\d+)/, $b =~ /(\d+)/);
      int $c <=> int $d
   } <$modules_dir/*>) {
   debug "Running $module...";
   for (split /\n/, `"$module" @HOSTS`) {
      my ($host, $code, $text) = split /\//, $_, 3;

      my $module_name = (split /\//, $module)[-1];
      $modules{$module_name} = 1;

      push @{ $result{$host}->{$module_name} }, [ $code, $text ];
   }
}

# Calculate total and summary statuses
for my $host (keys %result) {
   my $status = "ok";

   for my $module (keys %{$result{$host}}) {
      my $module_status = "ok";

      for my $result (@{$result{$host}->{$module}}) {
         if ($result->[0] eq "err") {
            $status = "err";
            $module_status = "err";
         } elsif ($result->[0] eq "warn") {
            $status = "warn" if $status eq "ok";
            $module_status = "warn" if $module_status eq "ok";
         } elsif ($result->[0] eq "messages") {
            $status = "messages" if $status eq "ok";
            $module_status = "messages" if $module_status eq "ok";
         }
      }

      $summary{$host}->{$module} = $module_status;
   }

   $total{$host} = $status;
}

# Format output
if ($conf{OUTPUT} =~ /^te?xt$/i) {
   printf "%47s\n", " = Explodiag = ";

   printf "\n%52s\n", " == Total statistics == ";
   printf "%16s | %4s\n", $_, $total{$_} for sort keys %total;

   printf "\n%55s\n", " == Per module statistics == ";
   for my $host (sort keys %summary) {
      printf "%16s | %32s | %4s\n", $host, $_, $summary{$host}->{$_} for
      sort {
         my ($c, $d) = ($a =~ /(\d+)/, $b =~ /(\d+)/);
         int $c <=> int $d
      } keys %{$summary{$host}};
   }

   printf "\n%54s\n", " == Detailed statistics == ";
   for my $module_name (sort {
         my ($c, $d) = ($a =~ /(\d+)/, $b =~ /(\d+)/);
         int $c <=> int $d
      } keys %modules) {
      print " === $module_name === \n";

      for (sort keys %result) {
         printf "%16s\n", $_;
         printf "%16s | %s\n", @$_ for @{ $result{$_}->{$module_name} };
      }
   }
} elsif ($conf{OUTPUT} =~ /^dump$/i) {
   require Data::Dumper;

   # Double use to avoid warning
   local $Data::Dumper::Purity;
   $Data::Dumper::Purity = 1;

   print Data::Dumper->Dump([\%total], ["explodiag_brief"]);
   print Data::Dumper->Dump([\%summary], ["explodiag_modules"]);
   print Data::Dumper->Dump([\%result], ["explodiag_full"]);
} elsif ($conf{OUTPUT} =~ /^html?$/i) {
   my $modules_count = 0+(keys %modules);
   print "<!DOCTYPE html><html><head><title>Explodiag</title>";

   print "<style type=text/css>
   table { border-collapse: collapse; }
   td { border: 1px solid black; padding: 4px; }
   a { text-decoration: none; color: black; }
   .ok { background-color: lightgreen; }
   .warn { background-color: yellow; }
   .err { background-color: darksalmon; }
   .messages { background-color: skyblue; }
   </style>";
   
   print "</head><body>\n";
   
   print "<hr><h3>Total statistics</h3>\n";
   print "<table>\n";
   printf "<tr><td><a href=#%s>%s</a></td><td class=%s>%s</td></tr>", $_, $_,
      $total{$_}, $total{$_} for sort keys %total;
   print "</table>\n";

   print "<hr><h3>Per module statistics</h3>\n";
   print "<table>\n";
   for my $host (sort keys %summary) {
      my $line = 0;
      for (sort {
         my ($c, $d) = ($a =~ /(\d+)/, $b =~ /(\d+)/);
         int $c <=> int $d
      } keys %{$summary{$host}}) {
         print "<tr>";
         print "<td id=$host rowspan=$modules_count>$host</td>" unless $line++;
         printf "<td><a href=#%s>%s</a></td><td class=%s>%s</td></tr>\n", $_,
         $_, $summary{$host}->{$_}, $summary{$host}->{$_};
      }
   }
   print "</table>\n";

   print "<hr><h3>Detailed statistics</h3>\n";
   for my $module_name (sort {
         my ($c, $d) = ($a =~ /(\d+)/, $b =~ /(\d+)/);
         int $c <=> int $d
      } keys %modules) {
      print "<h4 id=$module_name>$module_name</h4>\n";

      print "<table>\n";
      for (sort keys %result) {
         my @arr = @{ $result{$_}->{$module_name} };
         my $line = 0;

         print "<tr>";
         printf "<td rowspan=" . (0+@arr) . ">$_</td>" unless $line++;
         printf "<td class=%s>%s</td><td>%s</td></tr>\n", $_->[0], @$_ for sort
         {
            my ($c, $d) = ($a->[1] =~ /(\d+)/, $b->[1] =~ /(\d+)/);
            int $d <=> int $c
         } @arr;
      }
      print "</table>\n";
   }

   print "<hr><br>With love, KorG.</body></html>";
} else {
   die "Unknown output format: $conf{OUTPUT}\n";
}

END {
   # Remove temp directory
   chdir "/" or die $!;
   `rm $conf{RM_ARGS} "$conf{PREFIX}/$conf{DEST}/"` if $conf{CLEANUP}
}
