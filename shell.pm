package shell; # the PERL5LIB must be set to favor . before the core directories.  Otherwise another Shell.pm is used.

use strict; use warnings;
use helpers;
use FindBin '$Bin'; # other programs such as morbo may also use Bin and ruin our bin.
	say "bin is $Bin"; # for debugging purposes only
use File::Path 'make_path';
use Time::Stamp -stamps => { us=>1 }; # micro-seconds=>true

#################################### HELPER FUNCTIONS ####################################
sub subtract{
	my ($long,$short) = @_;
	return substr( $long, length $short )
}

######################################## NEW SHELL ########################################
sub new{
	my $packagename = shift;
	my ( $shellname, $room ) = @_;



# we need to see what's going on with the csh and tcsh prompt. ksh too, but different.




	# tested on Macbook Air::::::
	# interactive mode WORKS for bash, sh, csh, tcsh, ksh, but NOT rbash, dash, static-sh, sh.distrib, bsd-csh, ksh93, zsh, zsh5, rzsh
	# non-interactive mode works for bash, zsh, sh (need to do full testing for this category)
	# NEED TO IMPLEMENT NON INTERACTIVE MODE ALONGSIDE.  BOTH OPTIONS SHOULD BE AVAILABLE.
	# interactive mode shows the prompts, non-interactive shows just the outputs

	my $outputdirpath = "$Bin/rooms/".$room->name;
	make_path($outputdirpath);
	my $outputpath = "$outputdirpath/".localstamp().".$shellname";
#	open( my $handle, '|-', "$shellname -i &>$outputpath" ) or die "Could not open the $shellname shell!";
	open( my $handle, '|-', "$shellname &>$outputpath" ) or die "Could not open the $shellname shell!";

	my $prompt = 'MFQCLYDSHREDKZKJ'; # maybe not needed at all.(non interactive)
	#print $handle "PS1=$prompt\n";

	bless { name=>$shellname, handle=>$handle, prompt=>$prompt, outputpath=>$outputpath } => $packagename;
}

########################################## SHELL ##########################################

sub name{
	my $shell = shift;
	return $$shell{name}
}

sub handle{
	my $shell = shift;
	return $$shell{handle}
}
sub close_handle{
	my $shell = shift;
	$$shell{handle} = undef;
}

sub prompt{
	my $shell = shift;
	return $$shell{prompt}
}

sub output_path{
	my $shell = shift;
	return $$shell{outputpath}
}

sub output{
	my $shell = shift;
	my $outputpath = $shell->output_path;
	return `cat < $outputpath`
}

sub output_since{
	my $shell = shift;
	my ($outbefore) = @_;
	# outnow will not be equal to shell->output because the command is in there
	# this means that even if output hasn't come out yet, we think it's done! :(
	# the solution is to wait for output to end with the PROMPT :)
	my $outnow; my $stop; my $PS1 = quotemeta( $shell->prompt ); # assuming the prompt won't change
	do{
		$outnow = $shell->output;
		++$stop;
	}
	while( $outnow !~ /$PS1$/ and print "stop is $stop.  " and $stop < 99 );

	unless( defined $outnow ){ die 'outnow is not defined.' } # for debugging only
	return subtract( $outnow, $outbefore ) # this is only the new stuff.
}

sub command{ # executes command and returns the new output
	my $shell = shift;
	my ($command) = @_; # incoming command does not have a \n at the end.

	my $outbefore = $shell->output;

	my $handle = $shell->handle;
	print $handle "$command\n"; # \n is needed at the end of the command to send it, of course.

	return $shell->output_since($outbefore);
}

sub close{
	my $shell = shift;
	$shell->command('exit 0');
	close( $shell->handle ) or die 'Could not close the shell by its handle.';
	$shell->close_handle; # burn the bridge by undefining the handle. May not be necessary.
}

1
