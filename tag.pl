#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use Getopt::Long;

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

my $in_file = "tag_$classify_name";
my @if_cnt;
if (! -f $in_file) {
	GM::error("Tag file<$in_file> not exists, please run prepare.pl frist.");
}
else {
	open my $ifh, "< $in_file";
	@if_cnt = <$ifh>;
	close $ifh;
}

say "Start to tag <$classify_name> for release <$release_ver> ...";

foreach my $tt (@if_cnt) {
	my ($url, $ver) = split(/\|/, $tt);
	chomp $url;
	chomp $ver;

	my $tag_path = $url;
	$tag_path =~ s/${CFG::trunck_root_url}\/?//;
	$tag_path =~ s/(.*\/).+/$1/;
	$tag_path = "${CFG::tag_root_dir}/${release_ver}/${tag_path}";
	if (!-d $tag_path) {
		GM::exe_cmd("svn mkdir --parents $CFG::svn_cer $tag_path");
	}
	GM::exe_cmd("svn copy $CFG::svn_cer -r $ver '$url' '$tag_path'");
}

unlink($in_file);
