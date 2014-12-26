#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Getopt::Long;
use Spreadsheet::XLSX;

BEGIN {push @INC, q[./lib]};
use GM;
use RN;
no warnings 'once';

GM::init("conf/ar.conf");

my $classify_name = '';
my $tag = '';
my $release_ver = '';
GetOptions (
    'c|classify=s' => \$classify_name,
    't|tag=s' => \$tag,
    'v|version=s' => \$release_ver,
);

my $in_file = "pp_$classify_name";
my @if_cnt;
if (!-e $in_file) {
	GM::error("Prepare file<$in_file> not exists, please run prepare.pl frist.");
}
else {
	open my $ifh, "< $in_file";
	@if_cnt = <$ifh>;
	close $ifh;
}

my $rn_file = $CFG::rls_root_dir."/".$release_ver."/".$CFG::rn_path;
my $base_dir = $CFG::base_root_dir.'/'.$tag;
my $pre_dir = $CFG::pre_root_dir."/".$release_ver;

if (! exists $CFG::prebuild->{$classify_name}) {
	GM::error("Classify[$classify_name] does not exists.");
}

say "Start Prebuild <$classify_name> for Release<$release_ver> on Base<$tag> ...";

if (!-d $base_dir) {
	GM::error("Tag[$tag] does not exists.");
}

GM::exe_cmd("svn update $CFG::svn_cer $CFG::rls_root_dir");

if (!-f $rn_file) {
	GM::error("RN[$rn_file] does not exists.");
}

say "Parsing <", (split('/', $rn_file))[-1], "> ...";

my $book = Spreadsheet::XLSX->new($rn_file);
my $sheet = $book->worksheet($CFG::rn_sht_comm);

my %rvs; # Values for current row.

open my $ofh, "> pb_$classify_name";
my ($row_min, $row_max) = RN::update_col_idx($sheet, $CFG::comm_col);
foreach my $row ($row_min..$row_max) {
	RN::get_rvs($CFG::comm_col, $CFG::comm_cel, $classify_name, $sheet, $row, \%rvs);

	foreach my $pp_l (@if_cnt) {
		my ($_name, $_bpath, $_rname) = split(':', $pp_l);
		if ($rvs{'name'} eq $_name 
			&& defined $rvs{'build_path'}
			&& defined $rvs{'rst_path'}) {
			if (defined $rvs{'name_sub'}) {
				say "\t$_bpath/$rvs{'name_sub'}";
				GM::exe_cmd("rm -rf $base_dir/$rvs{'build_path'}");
				GM::exe_cmd("cp -r $_bpath/$rvs{'name_sub'} $base_dir/$rvs{'build_path'}");

				if (exists $CFG::android_results->{$rvs{'name'}}->{$rvs{'name_sub'}}) {
					my $rst_path = $CFG::android_results->{$rvs{'name'}}->{$rvs{'name_sub'}};
					$rst_path =~ s/\*(\w+)/$rvs{$1}/g;
					$rst_path =~ s{([^/]+)/../}{}g;

					print $ofh $rvs{'name'}.":".$base_dir."/".$rst_path.':'.$rvs{'rst_path'}."\n";
				}
			}
			else {
				say "\t$_bpath";
				GM::exe_cmd("for f in `ls $_bpath/`;"
					."do rm -rf $base_dir/$rvs{'build_path'}/\$f; done");
				GM::exe_cmd("cp -r $_bpath/* $base_dir/$rvs{'build_path'}");

				print $ofh $rvs{'name'}.":".$base_dir."/".$CFG::android_results->{'DEFAULT'}.':'.$rvs{'rst_path'}."\n";
			}
		}
	}
}
close $ofh;

GM::finish();
unlink($in_file);
