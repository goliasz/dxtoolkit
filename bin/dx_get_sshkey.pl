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
# Program Name : dx_get_sshkey.pl
# Description  : Get appliance public ssh key
# Author       : Marcin Przepiorowski
# Created      : 08 Jun 2015 (v2.0.0)
#
# 

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
use System_obj;
use Databases;
use Toolkit_helpers;

my $version = $Toolkit_helpers::version;

GetOptions(
  'help|?' => \(my $help), 
  'd|engine=s' => \(my $dx_host), 
  'all' => \(my $all),
  'debug:i' => \(my $debug), 
  'version' => \(my $print_version),
  'dever=s' => \(my $dever)
) or pod2usage(-verbose => 2, -output=>\*STDERR, -input=>\*DATA);

pod2usage(-verbose => 2, -output=>\*STDERR, -input=>\*DATA) && exit if $help;
die  "$version\n" if $print_version;   

my $engine_obj = new Engine ($dever, $debug);
my $path = $FindBin::Bin;
my $config_file = $path . '/dxtools.conf';

$engine_obj->load_config($config_file);

# this array will have all engines to go through (if -d is specified it will be only one engine)
my $engine_list = Toolkit_helpers::get_engine_list($all, $dx_host, $engine_obj); 

if (scalar(@{$engine_list}) > 1) {
  print "More than one engine is default. Use -d parameter\n";
  exit(3);
}



for my $engine ( sort (@{$engine_list}) ) {
  # main loop for all work

  if ($engine_obj->dlpx_connect($engine)) {
    print "Can't connect to Dephix Engine $engine\n\n";
    exit(1);
  } 


  # load objects for current engine
  my $system = new System_obj( $engine_obj, $debug);
  print $system->getSSHPublicKey();
 

}


__DATA__

=head1 SYNOPSIS

dx_get_sshkey.pl [ -d <delphix identifier> ] [ -help|? ]

=head1 ARGUMENTS

=over 4

=item B<-d>
Delphix Identifier (hostname defined in dxtools.conf). 


=back

=head1 OPTIONS

=over 4

=item B<-help>          
Print this screen

=item B<-debug>
Turn on debugging

=back


=cut



