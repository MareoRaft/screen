package room;

use strict; use warnings; use matt_profile;
use setscreen;
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

sub htmlify{
	my ($str) = @_;
	$str =~ s|\n|<br />|g;
	return $str
}

######################################## NEW ROOM ########################################
sub new{
	my $packagename = shift;
	my %options = @_; # includes the NAME of the room.   # take in desired shell too?
	open( my $SHH, '|-', '/bin/bash' ) or die 'Could not open shell!';
	bless { %options, shh=>$SHH, controllers=>set->new, output=>'' } => $packagename
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

sub append{
	my $room = shift;
	my ($string) = @_;
	$string = htmlify($string);
	$$room{output} .= $string;
	$room->jblast( command=>'append', output=>$string );
	#say "output is now $$room{output}";
}

sub jblast{ # blast is replaced with jblast, which includes the json in it
	my $room = shift;
	say 'jblasting to '.scalar $room->controllers->array.' controllers.';
	my %ball = @_; say 'ball is '."@_";
	foreach( $room->controllers->array ){ say 'i have a controller '."$_"; $_->jsend(%ball) };
	say 'done WITH CONTROLLERS';
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

sub command{ # executes a shell command and relays the output to all controllers.
	my $room = shift;
	my ($command) = @_;
	say "command is $command"; #say "Bin is $Bin";
	$room->append("<span class='prompt'>$prompt</span><span class='command'>$command</span>");
	# capture special room commands: shells
	# probably not needed: nvm
	#say "shell handle is $SHH";
	
	# FYI, this is just a regular file; it's not a pipe.

	my $SHH = $room->SHH; print $SHH qq(($command) &> /Users/Matthew/Desktop/dirme/pipe\n); # \n is NECESSARY to send or flush command
	# get the output somehow AND also store it into a package string.
	my $output = `cat < /Users/Matthew/Desktop/dirme/pipe`; #say "got output: $output.END";
	$room->append($output);
}

sub close{
	my $room = shift;
	$room->command('exit 0');
	close( $room->SHH );
	# tell all controllers to leave (add this soon)
	delete $nametoroom{ $room->name };
}

1
