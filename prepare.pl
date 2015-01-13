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

my $rn_file = $CFG::rls_root_dir."/".$release_ver."/".$CFG::rn_path;
my $base_dir = $CFG::base_root_dir.'/'.$tag;
my $pre_dir = $CFG::pre_root_dir."/".$release_ver;

if (! exists $CFG::func_cel->{$classify_name}) {
	GM::error("Classify[$classify_name] does not exists.");
}

say "Start Prepare <$classify_name> for Release<$release_ver> ...";

if (!-d $base_dir) {
	GM::error("Tag[$tag] does not exists.");
}

GM::exe_cmd("svn update $CFG::svn_cer $CFG::rls_root_dir");

if (!-f $rn_file) {
	GM::error("RN[$rn_file] does not exists.");
}

GM::exe_cmd("rm -rf '$pre_dir/${classify_name}'");
GM::exe_cmd("mkdir -p '$pre_dir/${classify_name}'");

say "Parsing <", (split('/', $rn_file))[-1], "> ...";

my $book = Spreadsheet::XLSX->new($rn_file);
my $sheet = $book->worksheet($CFG::rn_sht_func);

my %rvs; # Values for current row.

open my $ofh, "> pp_${classify_name}";
open my $otfh, "> tag_${classify_name}";
my ($row_min, $row_max) = RN::update_col_idx($sheet, $CFG::func_col);
foreach my $row ($row_min..$row_max) {
	RN::get_rvs($CFG::func_col, $CFG::func_cel,
		$classify_name, $sheet, $row, \%rvs);

	if ($rvs{classify} eq $classify_name
		&& (defined $rvs{enable} && $rvs{enable} =~ m/^yes$/i)) {
		my $export_ver = '';
		my $export_dir = '';
		my @export_targets = ();

		print "\tRow: ", $row + 1, " - $rvs{name}";

		if (defined $rvs{version} && $rvs{version} ne '-') {
			if ($rvs{version} =~ m/^r\d+$/i) {
				print " - $rvs{version}";
				$export_ver = "-r $rvs{version}";
			}
			else {
				say '';
				GM::error("Invalid version [$rvs{version}] for [$rvs{name}], in row ".($row + 1));
			}
		}
		say '';

		if ($CFG::func_url->{$classify_name}) {
			if ($rvs{$CFG::func_url->{$classify_name}} =~ m/^\s*all\s*$/i) {
				push @export_targets, '';
			}
			else {
				push @export_targets, split(',', $rvs{$CFG::func_url->{$classify_name}});
			}
		}
		else {
			push @export_targets, '';
		}

		$export_dir = $rvs{trunckurl};
		$export_dir =~ s/${CFG::trunck_root_url}\/*//;
		$export_dir = $pre_dir.'/'.$export_dir.'/';

		GM::exe_cmd("mkdir -p '$export_dir'");

		foreach my $target (@export_targets) {
			$target =~ s/^\s+//;
			$target =~ s/\s+$//;
			my $each_target = $export_dir.'/'.$target;
			my $each_url = $rvs{trunckurl}.'/'.$target;

			GM::exe_cmd("rm -rf '$each_target'");
			GM::exe_cmd("svn export $CFG::svn_cer $export_ver '$each_url' '$each_target'");

			print $otfh get_version($each_url, $export_ver)."\n";
		}

		print $ofh "$rvs{name}:$export_dir:";
		if (defined $rvs{$CFG::func_url->{$classify_name}}) {
			print $ofh "$rvs{$CFG::func_url->{$classify_name}}";
		}
		print $ofh "\n";
	}
}
close $ofh;
close $otfh;

sub get_version {
	my $url = shift;
	my $version = shift;

	if ($version) {
		$version =~ s/-r\s+//;
		return "${url}|${version}";
	}
	else {
		my @_ver = `svn log -l1 -q "$url"`;
		say "@_ver";
		my $crt_vet = (split(/\|/, $_ver[1]))[0];
		$crt_vet =~ s/^\s+//;
		$crt_vet =~ s/\s+$//;
		say "\$crt_vet = [$crt_vet]";
		return "${url}|${crt_vet}"
	}
}

GM::finish();
