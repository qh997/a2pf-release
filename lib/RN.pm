package RN;
use 5.010;
use Spreadsheet::XLSX;
use GM;

sub update_col_idx {
	my $sheet = shift;
	my $col_conf = shift;

	my ($row_min, $row_max) = $sheet->row_range();
	my ($col_min, $col_max) = $sheet->col_range();
	my ($rs, $re) = ($row_min, $row_max);

	my $keys_no = keys(%$col_conf);
	foreach (keys(%$col_conf)) {
		if (!$col_conf->{$_}->{'name'}) {
			$keys_no--;
		}
	}

	foreach my $row ($row_min..$row_max) {
		my $this_is = $keys_no;
		foreach my $col ($col_min..$col_max) {
			my $cell = $sheet->get_cell($row, $col);

			next unless defined $cell;

			my $cell_val = $cell->value();
			foreach my $alias (keys %$col_conf) {
				if ($cell_val eq $col_conf->{$alias}->{'name'}) {
					if ($col_conf->{$alias}->{'col'} != $col) {
						GM::error("Column <$cell_val>("
							.$col_conf->{$alias}->{'col'}
							.") is different from RN($col)", 'W');
						$col_conf->{$alias}->{'col'} = $col;
					}

					$this_is--;
					$rs = $row + 1;
				}
			}

			if (0 == $this_is) {
				return ($rs, $re);
			}
		}

		if ($this_is != $keys_no) {
			GM::error("There is something strange in RN row $row($this_is).", 'W');
		}
	}
}

sub get_rvs {
	my $col_conf = shift;
	my $cell_conf = shift;
	my $classify_name = shift;
	my $sheet = shift;
	my $row = shift;
	my $rvals = shift;

	while (my ($idx, $val) = each %$col_conf) {
		my $cell = $sheet->get_cell($row, $val->{'col'});
		my $type = $cell_conf->{$classify_name}->{$idx};

		if ((($type == 1 || $type == 2) && defined $cell)) {
			$rvals->{$idx} = $cell->value();
		}
		elsif ($type != 2) {
			$rvals->{$idx} = undef;
		}
	}
}

return 1;
