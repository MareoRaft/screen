package room;

use strict; use warnings; use matt_profile;
use set; # this version of set allows us to use the set as an array (still must type @{obj->controllers})
use FindBin '$Bin'; # other programs such as morbo may also use Bin and ruin our bin.
say "findbin is $FindBin::Bin and bin is $Bin";

#################################### HELPER FUNCTIONS ####################################
######################################## NEW ROOM ########################################
sub new{
	my $packagename = shift;
	my ($roomname) = @_; # take in desired shell too?
	open( my $SHH, '|-', '/bin/zsh' ) or die 'Could not open shell!';
	bless { name=>$roomname, shh=>$SHH, controllersset=>set->new, output=>'' } => $packagename
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

sub controllers_set{
	my $room = shift;
	return $$room{controllersset}
}
sub controllers{
	my $room = shift;
	return @{$room->controllers_set}
}
sub add_controller{
	my $room = shift;
	my ($controller) = @_;
	$room->controllers_set->add_element($controller)
}
sub remove_controller{ say 'removing a controller...';
	my $room = shift;
	my ($controller) = @_;
	$room->controllers_set->remove_element($controller);
	# check if the room is empty.  if so, close the room.
	#if( $room->controllers_set->is_empty ){ say 'closing the room...'; $room->close }
}

sub __get_output{ # this gets the output from the temporary file, then deletes the file.
	my $output;
		system(qq(touch "$Bin/output.txt")) and die "Can't touch $Bin/output.txt"; # remember, system returns 0 on success!
			open( my $fh, '<', "$Bin/output.txt" ) or die "Could not open $Bin/output.txt";
				{ local $/ = undef; chomp( $output = <$fh> ) }
			close( $fh );
		system(qq(rm "$Bin/output.txt"));
	return $output
}

sub output{ # gets all the output of a room for a new self joining in
	my $room = shift;
	return $$room{output}
}

sub append{
	my $room = shift;
	my ($string) = @_;
	$$room{output} .= $string;
	say "output is now $$room{output}";
}

sub jblast{ # blast is replaced with jblast, which includes the json in it
	my $room = shift;
	my ($inforef) = @_;
	foreach( $room->controllers ){ $_->jsend($inforef) };
}

use overload
	'""' => \&stringify;

sub stringify{
	my $room = shift;
	my $toprint;
	{
	local $" = ',';
		$toprint .= 'Roomname is '.$room->name."\n";
		my @controllers = $room->controllers; $toprint .= "Controllers are: @controllers\n";
	}
	return $toprint
}

sub command{ # executes a shell command and relays the output to all controllers.
	my $room = shift;
	my ($command) = @_;
	say "command is $command"; say "Bin is $Bin";
	# capture special room commands: shells
	# probably not needed: nvm
		my $SHH = $room->SHH;

	say "shell handle is $SHH";
	print $SHH 'echo "i am supposed to be zsh!!!!"';
 print $SHH qq($command &>"$Bin/output.txt"\n);
	# get the output somehow AND also store it into a package string.
	my $output = __get_output(); say "got output: $output.END";
	$room->append($output);
	$room->jblast( command=>'append', output=>$output );
}

sub close{
	my $room = shift;
	$room->command('exit 0');
	close( $room->SHH );
	# tell all controllers to leave (add this soon)
	delete $mojo::roomnametoroom{ $room->name };
}

1
