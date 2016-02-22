package helpers;

use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(trim say);

sub trim_scalar{ my $i = shift; $i =~ s/^\s+|\s+$//g; $i }
sub trim{
	if( wantarray ){
		return map { trim_scalar($_) } @_
	}
	else{
		return trim_scalar( join("\n",@_) )
	}
}

sub say{ print @_; print "\n" }

1
