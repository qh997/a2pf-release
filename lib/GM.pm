package GM;
use 5.010;

our @EXPORT = qw(init);

my $err_log = "error.log";
my $cmd_log = "command.log";
my @err_msg;
my @cmd_msg;

sub init {
	$_config_file = shift;
	unlink($err_log);
	unlink($cmd_log);

	if (my $err = load_config($_config_file)) {
		chomp $err;
		error("Load config error[$err].");
	}
}

sub finish {
	final($err_log, $cmd_log);
}

sub load_config
{
	my $file = shift;
	our $err;
	{   # Put config data into a separate namespace
		package CFG;
		# Process the contents of the config file
		my $rc = do $file;
		# Check for errors
		if ($@) {
			$::err = "ERROR: Failure compiling '$file' - $@";
		} elsif (! defined($rc)) {
			$::err = "ERROR: Failure reading '$file' - $!";
		} elsif (! $rc) {
			$::err = "ERROR: Failure processing '$file'";
		}
	}
	return ($err);
}

sub error {
	my $str = shift;
	my $warn = shift;
	chomp $str;

	$str = defined $warn ? 'WARNING - '.$str : 'ERROR - '.$str;
	push @err_msg, $str;
	say $str;

	final($err_log, $cmd_log);
	exit 1 unless defined $warn;
}

sub exe_cmd {
	my $cmd_str = shift;

	my $_cmd_str = $cmd_str;
	$_cmd_str =~ s/(--password\s+)\S+/$1******/;
	print '$ '.$_cmd_str."\n";

	push @cmd_msg, '$ '.$cmd_str."\n";
	my @output = `$cmd_str 2>&1`;
	my $retval = $?;

	print "@output\n";

	push @cmd_msg, @output;
	push @cmd_msg, "\n";

	if ($retval) {
		error("Bad command `$_cmd_str' ($retval)");
	}
}

sub final {
	my $_err = shift;
	my $_cmd = shift;

	if (0 != @err_msg) {
		open my $fh, "> $_err";
		print $fh join("\n", @err_msg);
		print $fh "\n";
		close $fh;
	}
	if (0 != @cmd_msg) {
		open my $fh, "> $_cmd";
		print $fh join('', @cmd_msg);
		close $fh;
	}
}

return 1;
