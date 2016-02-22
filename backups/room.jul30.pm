package room;

use strict; use warnings; use matt_profile;
use set;
use FindBin '$Bin'; # other programs such as morbo may also use Bin and ruin our bin.
say "findbin is $FindBin::Bin and bin is $Bin";

######################################### GLOBALS ########################################
our %nametoroom = ();
my $prompt = ''; #'$ ';

#################################### HELPER FUNCTIONS ####################################
our @namepool = ();
open( my $FH, '<', 'public/lexis.txt' ) or die 'Could not open the lexis!!!';
    push @namepool => &trim($_) while( <$FH> );
close( $FH ) or die 'Could not CLOSE the lexis!';

sub rand_name{
    my $randindex = int( $#namepool * rand() );
    return $namepool[$randindex]
}

sub name_to_room{ # creates a new room if necessary
    my ($name) = @_;
    return $nametoroom{$name} //= room->new(name=>$name) or die 'Bad room name string!' # adds the room to our hash if necessary
}

sub terminal_prompt{
	my $room = shift;
	return qr/bash-3\.2\$ /;
}

sub html_output{
	my $room = shift;
	return $$room{htmloutput}
}

sub append_to_html_output{
	my $room = shift;
	my ($string) = @_;
	$$room{htmloutput} .= $string;
}

sub htmlify_output{
	my $room = shift;
	my ($command,$str) = @_;
	# put a span around the command...
	$command = quotemeta $command;
	$str =~ s|^(?=$command)|<span class="command">|;
	$str =~ s|(?<=$command)|</span>|; # for some reason, ^ in regex makes it not find.  This regex is NOT global, so no issue.
	my $PS1 = $room->terminal_prompt;
	$str =~ s|$PS1$||; # delete final prompt (leave newline)
	$str =~ s|\n|<br />|g;
	return $str
}

sub subtract{
	my ($long,$short) = @_;
	return substr( $long, length $short )
}

######################################## NEW ROOM ########################################
sub new{
	my $packagename = shift;
	my %options = @_; # includes the NAME of the room.   # take in desired shell too?
	open( my $SHH, '|-', "/bin/bash -i &>$Bin/output.txt" ) or die 'Could not open shell!';
	bless { %options, shh=>$SHH, controllers=>set->new, output=>'', htmloutput=>'' } => $packagename
}

########################################## ROOM ##########################################
sub name{
	my $room = shift;
	return $$room{name}
}

sub SHH{
	my $room = shift;
	return $$room{shh}
}

sub controllers{
	my $room = shift;
	return $$room{controllers}
}
sub add_controller{
	my $room = shift;
	my ($controller) = @_;
	$room->controllers->add_element($controller)
}
sub remove_controller{ say 'removing a controller...';
	my $room = shift;
	my ($controller) = @_;
	$room->controllers->remove_element($controller);
	# check if the room is empty.  if so, close the room.
	if( $room->controllers->is_empty ){ say 'closing the room...'; $room->close }
}

sub output{ # gets all the output of a room for a new self joining in
	my $room = shift;
	return $$room{output}
}

sub append_to_output{
	my $room = shift;
	my ($string) = @_;
	$$room{output} .= $string;
}

sub append{
	my $room = shift;
	my ($command,$string) = @_;
	$room->append_to_output($string);
	$string = $room->htmlify_output($command,$string);
	$room->append_to_html_output($string);
	$room->jblast( command=>'append', output=>$string );
	#say "output is now $$room{output}";
}

sub jblast{ # blast is replaced with jblast, which includes the json in it
	my $room = shift;
	#say 'jblasting to '.scalar $room->controllers->array.' controllers.';
	my %ball = @_; say 'ball is '."@_";
	foreach( $room->controllers->array ){ #say 'i have a controller '."$_";
		$_->jsend(%ball)
	}
	#say 'done WITH CONTROLLERS';
}

use overload
	'""' => \&stringify;

sub stringify{
	my $room = shift;
	my $toprint;
	{
	local $" = ',';
		$toprint .= 'Roomname is '.$room->name."\n";
		my @controllers = $room->controllers->array; $toprint .= "Controllers are: @controllers\n";
	}
	return $toprint
}

sub get_output_for_command{
	my $room = shift;
	my ($command) = @_;
	# outnow will not be equal to room->output because the command is in there
	# this means that even if output hasn't come out yet, we think it's done! :(
	my $outnow; my $stop; my $PS1;
	do{
		$outnow = `cat < $Bin/output.txt`;
		$PS1 = $room->terminal_prompt;
		++$stop
	}while( $outnow !~ /$PS1$/ and print "stop is $stop.  " and $stop < 99 );
	return my $outappend = subtract( $outnow, $room->output );
}

sub command{ # executes a shell command and relays the output to all controllers.
	my $room = shift;
	my ($command) = @_; # incoming command does not have a \n at the end.
	say "command is $command"; #say "Bin is $Bin";
#	$room->append("<span class='prompt'>$prompt</span><span class='command'>$command</span>"); # this NOT NEEDED NOW THAT ENTIRE BASH IS PIPING
	# capture special room commands: shells
	#say "shell handle is $SHH";
	my $SHH = $room->SHH; print $SHH "$command\n"; # \n is needed at the end of the command to send it, of course.
	# get the output somehow AND also store it into a package string.
	my $outappend = $room->get_output_for_command($command); #say "got output: $output.END";
	$room->append($command,$outappend);
}

sub close{
	my $room = shift;
	$room->command('exit 0');
	close( $room->SHH );
	# tell all controllers to leave (add this soon)
	delete $nametoroom{ $room->name };
}

1
