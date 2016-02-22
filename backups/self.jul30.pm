package Mojolicious::Controller; # self is an extension of Mojolicious::Controller

use matt_profile;
use Switch;
use room;

################################################# DEFAULT VARIABLES ###############################################

################################################# HELPER FUNCTIONS ################################################

############################################## MOJOLICIOUS::CONTROLLER ############################################
sub jsend{ # send is replaced with jsend, which includes the json in it
    say 'jsending!!';
    my $self = shift;
    my %ball = @_;
    $self->send({ json => \%ball });
}

sub roomname{ # this function needs to return undef if there is no roomname yet! See mojo.pl line 26.
    my $self = shift;
        my ($name) = @_; if( defined $name ){ $self->session( roomname=>$name ) or die 'Bad roomname string!' }
    return $self->session(roomname)
}

sub room{
    my $self = shift;
    return room::name_to_room( $self->roomname ) # the session only stores the roomname.  To store both would be redundant.
}

sub join_room{
    my $self = shift;
    my ($name) = @_;
    $self->roomname($name);
    $self->room->add_controller($self); # don't forget to tell the room you are in it! Here a NEW ROOM IS CREATED if necessary
    $self->jsend( command=>'set', id=>'roomname', html=>$name, color=>'white' ); # update the page to reflect room
}

sub leave_room{
    my $self = shift;
    say 'leaving my room now!'."\n";
    $self->room->remove_controller($self); # the remove_controller function will check for an empty room.  If so, it closes the room.
}

sub change_room{ # change_room takes in a ROOMNAME, and changes self to that room.  Makes a new room if necessary.
    my $self = shift; say 'changing my room!!!!'."\n";
    my ($roomname) = @_;
        $self->leave_room;
        $self->join_room($roomname);
    return $roomname
}

sub command{
    my $self = shift;
    my ($command) = @_;
    #capture special INDIVIDUAL commands: help, user, room, disconnect, connect
    if( $command =~ /^(help|user|room|(?:dis)?connect)/i ){
        switch($1){
            case 'help' {say 'h'}
            case 'user' {say 'u'}
            case 'room' {say 'r'}
            case 'connect' {say 'c'}
            case 'disconnect' {say 'd'}
        }
        return 1
    }else{
        $self->room->command($command)
    }
}

sub retrieve_output{ # gets the current room output and sends it to self
    my $self = shift; say 'retrieving output!!!!!!!!!!!';
    my $htmloutput = $self->room->html_output;
    $self->jsend( command=>'append', output=>$htmloutput );
}


1
