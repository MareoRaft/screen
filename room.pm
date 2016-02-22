package room;

use strict; use warnings;
use feature 'switch';
use helpers;
use set;
use shell;

######################################### GLOBALS ########################################
our %nametoroom = ();

#################################### HELPER FUNCTIONS ####################################
our @namepool = ();
open( my $FH, '<', 'public/lexis.txt' ) or die 'Could not open the lexis!!!';
    push @namepool => trim(lc $_) while( <$FH> ); # rooms are stored as lowercase, so the keys must be lc too!
close( $FH ) or die 'Could not CLOSE the lexis!';

sub rand_name{
    my $randindex = int( $#namepool * rand() );
    return $namepool[$randindex]
}

sub name_to_room{ # creates a new room if necessary
    my ($name) = @_;
    return $nametoroom{$name} //= room->new(name=>$name) or die 'Bad room name string!' # adds the room to our hash if necessary
}

sub htmlify{ # this takes any amount of terminal stdout and converts it to html.
	my ( $str, $prompt ) = @_;
	# put a span around the commands...
	# $prompt = quotemeta $prompt;
	# $str =~ s|^(.*)\n|<span class="command">$1</span>\n|; # the very first command is NOT preceded by a prompt.
	# $str =~ s|\n?$prompt(.*)\n|\n<span class="command">$1</span>\n|g; # this also makes sure that prompts always start on new lines.
	# $str =~ s|\n?$prompt$|\n|; # delete final prompt.  Also, all endings have newlines regardless of what bash outputted.
	# $str =~ s|</span>\n$|\n\n|g; # for an outputless command, let's display an empty line to show that.
	$str =~ s|\n|<br />|g;
	return $str
}

######################################## NEW ROOM ########################################
sub new{
	my $packagename = shift;
	my %options = @_; # includes the NAME of the room.

	my $room = bless {
		name => $options{name},
		shell => undef,
		controllers => set->new,
		output => '',
	}
	=> $packagename;

	$room->shell('sh');

	return $room
}

########################################## ROOM ##########################################
sub name{
	my $room = shift;
	return $$room{name}
}

sub shell{
	my $room = shift;
	my ($shellname) = @_;
	if( defined $shellname ){
		$room->shell->close if defined $room->shell;
		$$room{shell} = shell->new( $shellname, $room );
		my $divider = "\n###############################################################\n";
		$room->append($divider."Welcome to a new $shellname shell!\n\n");
	}
	return $$room{shell}
}

sub controllers{ # this is a SET of controllers
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
	my ($string) = @_;
	$room->append_to_output($string);
#	my $html = htmlify( $string, $room->shell->prompt );
	my $html = htmlify( $string );
	$room->jblast( command=>'append', output=>$html );
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

sub command{ # executes a shell command and relays the output to all controllers.
	my $room = shift;
	my ($command) = @_; # incoming command does not have a \n at the end.
	say "command is $command"; #say "Bin is $Bin";
	if( $command =~ /^(shell) +([^ ]*)/i ){ # capture special room commands: shells
		my $keyword = $1;
        my $argument = lc trim $2;
        given($keyword){
	        when('shell'){ # the argument has already been verified in $self->command
	            $room->shell($argument);
	            $room->jblast( command=>'set', id=>'shellname', html=>$argument, color=>"#f12772" );
	        }
	    }
    }
    else{
#    	my $outappend = $room->shell->command($command);
    	my $outappend = "<span class='command'>$command</span><br />" . $room->shell->command($command);
		$room->append($outappend);
	}
}

sub close{
	my $room = shift;
	$room->shell->close;
	# tell each controller in the room to leave the room (reset roomname attribute, remove self from room->controllers, update GUI
	foreach my $self ( $room->controllers->array ){ $self->leave_room }
	delete $nametoroom{ $room->name }; # delete the room from the nametoroom hash
}

1
