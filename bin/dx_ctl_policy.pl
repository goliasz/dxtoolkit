# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2015,2016 by Delphix. All rights reserved.
#
# Program Name : dx_ctl_policy.pl
# Description  : Import policy 
# Author       : Marcin Przepiorowski
# Created      : 14 April 2015 (v2.1.0)

use strict;
use warnings;
use JSON;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev); #avoids conflicts with ex host and help
use File::Basename;
use Pod::Usage;
use FindBin;
use Data::Dumper;

my $abspath = $FindBin::Bin;

use lib '../lib';
use Engine;
use Formater;
use Policy_obj;
use Toolkit_helpers;
use Databases;
use Group_obj;

my $version = $Toolkit_helpers::version;

GetOptions(
  'help|?' => \(my $help), 
  'd|engine=s' => \(my $dx_host), 
  'filename|n=s' => \(my $filename), 
  'indir=s' => \(my $indir),
  'import' => \(my $import),
  'update' => \(my $update),
  'mapping=s' => \(my $mapping),
  'debug:i' => \(my $debug), 
  'dever=s' => \(my $dever),
  'all' => (\my $all),
  'version' => \(my $print_version)
) or pod2usage(-verbose => 2, -output=>\*STDERR, -input=>\*DATA);


pod2usage(-verbose => 2, -output=>\*STDERR, -input=>\*DATA) && exit if $help;
die  "$version\n" if $print_version;   

my $engine_obj = new Engine ($dever, $debug);
my $path = $FindBin::Bin;
my $config_file = $path . '/dxtools.conf';

$engine_obj->load_config($config_file);

if (defined($all) && defined($dx_host)) {
  print "Option all (-all) and engine (-d|engine) are mutually exclusive \n";
  pod2usage(-verbose => 2, -output=>\*STDERR, -input=>\*DATA);
  exit (1);
}

if (defined($filename) && defined($indir) ) {
  print "Option filename and indir are mutually exclusive \n";
  pod2usage(-verbose => 2, -output=>\*STDERR, -input=>\*DATA);
  exit (1);
}

if ( ( ! defined($filename)  ) && ( ! defined($indir) ) && ( ! defined($mapping) ) ) {
  print "Option filename, indir or mapping is required \n";
  pod2usage(-verbose => 2, -output=>\*STDERR, -input=>\*DATA);
  exit (1);
}

# this array will have all engines to go through (if -d is specified it will be only one engine)
my $engine_list = Toolkit_helpers::get_engine_list($all, $dx_host, $engine_obj); 

my $ret = 0;

for my $engine ( sort (@{$engine_list}) ) {
  # main loop for all work
  if ($engine_obj->dlpx_connect($engine)) {
    print "Can't connect to Dephix Engine $dx_host\n\n";
    next;
  };

  # load objects for current engine
  my $policy = new Policy_obj( $engine_obj, $debug);

  if (defined($mapping)) {
    my $db = new Databases ( $engine_obj, $debug );
    my $groups = new Group_obj ( $engine_obj, $debug );
    if ($policy->applyMapping($mapping, $groups, $db)) {
      print "Error in applying mapping\n";
      exit 1;
    }
  } else {

    if (defined($filename)) {
      if (defined($import)) {
        if ($policy->importPolicy($filename)) {
          print "Problem with load policy from file $filename\n";
          exit 1;
        }
      } elsif (defined($update)) {  
        if ($policy->updatePolicy($filename)) {
          print "Problem with update policy from file $filename\n";
          exit 1;
        }
      }
    } else {
      opendir (my $DIR, $indir) or die ("Can't open a directory $indir : $!");

      while (my $file = readdir($DIR)) {
          # take only .template files
          if ($file =~ m/\.policy$/) {
            my $filename = $indir . "/" . $file;
            if (defined($import)) {
              if ($policy->importPolicy($filename)) {
                print "Problem with load policy from file $filename\n";
                $ret = $ret + 1;
              }
            } elsif (defined($update)) {  
              if ($policy->updatePolicy($filename)) {
                print "Problem with update policy from file $filename\n";
                $ret = $ret + 1;
              }
            }        
          }
      }

      closedir ($DIR);
    }
  }


}


exit $ret;

__DATA__

=head1 SYNOPSIS

 dx_ctl_policy.pl [ -engine|d <delphix identifier> | -all ] -import | -update | -mapping mapping_file [ -filename filename | -indir dir]  [ -help|? ] [ -debug ] 

=head1 DESCRIPTION

Import or update a Delphix Engine policy from file name or directory.

=head1 ARGUMENTS

Delphix Engine selection - if not specified a default host(s) from dxtools.conf will be used.

=over 10

=item B<-engine|d>
Specify Delphix Engine name from dxtools.conf file

=item B<-all>
Display databases on all Delphix appliance

=item B<-import>                                                                                                                                            
Import policy from file or directory

=item B<-update>                                                                                                                                            
Update policy from file or directory

=item B<-mapping mapping_file>                                                                                                                                            
Apply policy to databases / groups using mapping file mapping_file

=back

=head1 OPTIONS

=over 3


=item B<-filename>
Template filename

=item B<-indir>                                                                                                                                            
Location of imported templates files


=item B<-help>          
Print this screen

=item B<-debug>
Turn on debugging

=back




=cut



