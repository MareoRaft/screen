package Mojolicious::Controller; # self is an extension of Mojolicious::Controller

use strict; use warnings;
use feature 'switch';
use helpers;
use room;

################################################# DEFAULT VARIABLES ###############################################

################################################# HELPER FUNCTIONS ################################################

############################################## MOJOLICIOUS::CONTROLLER ############################################
sub jsend{ # send is replaced with jsend, which includes the json in it
    #say 'jsending!!';
    my $self = shift;
    my %ball = @_;
    $self->send({ json => \%ball });
}

sub roomname{ # this function needs to return undef if there is no roomname yet! See mojo.pl line 26.
    my $self = shift;
        my ($name) = @_; if( defined $name ){ $self->session( roomname=>$name ) or die 'Bad roomname string!' }
    return $self->session('roomname')
}
sub reset_roomname{
    my $self = shift;
    $self->session( roomname=>undef );
}

sub room{
    my $self = shift;
    return room::name_to_room( $self->roomname ) # the session only stores the roomname.  To store both would be redundant.
}

sub join_room{
    my $self = shift;
    my ($name) = @_;
        $name = lc $name; # important!
    $self->roomname($name); # order matters...
    $self->room->add_controller($self); # don't forget to tell the room you are in it! Here a NEW ROOM IS CREATED if necessary
    $self->jsend( command=>'clear' ); # clear self's webpage content
    $self->retrieve_output; # update self's webpage with the output for the new room.
    $self->jsend( command=>'set', id=>'status', html=>'connected', color=>"#0d0" );
    $self->jsend( command=>'set', id=>'roomname', html=>$name, color=>'white' ); # update the page to reflect room...
    $self->jsend( command=>'set', id=>'shellname', html=>$self->room->shell->name, color=>"#f12772" ); # ...and shell
}

sub leave_room{
    my $self = shift;
    say 'leaving my room now!'."\n";
    $self->room->remove_controller($self); # the remove_controller function will check for an empty room.  If so, it closes the room.
    $self->reset_roomname; # ...order matters
    $self->jsend( command=>'set', id=>'status', html=>'disconnected', color=>'red' );
    $self->jsend( command=>'set', id=>'roomname', html=>'none', color=>'red' ); # update the page to reflect room
    #$self->jsend( command=>'hide', id=>'roomname' ); # hide the roomname. ORDER MATTERS # i'd rather not hide the roomname
    $self->jsend( command=>'set', id=>'shellname', html=>'none', color=>'red' ); # update the page to reflect room
}

sub change_room{ # change_room takes in a ROOMNAME, and changes self to that room.
    my $self = shift; say 'changing my room!!!!'."\n";
    my ($roomname) = @_;
        $self->leave_room;
        $self->join_room($roomname);
    return $roomname
}

sub command{ # these are the special SCREEN commands:
    my $self = shift;
    my ($command) = @_;
    #capture special INDIVIDUAL commands: help, user, room, disconnect, connect
    if( $command =~ /^(shell|user|room|eval)(.*)$/is ){
        my $keyword = $1;
        my $argument = trim $2; # ditto
        given($keyword){
            when('shell'){
                if( $argument =~ /^(bash|rbash|dash|sh|static-sh|sh\.distrib|csh|bsd-csh|tcsh|ksh|ksh93|zsh|zsh5|rzsh)$/i ){
                    $self->room->command(lc $command) # remember, this is a ROOM special command
                }
                else{
                    $self->jsend( command=>'alert', string=>qq(The shell "$argument" is not supported.) )
                }
            }
            when('user'){ $self->jsend( command=>'set', id=>'username', html=>lc($argument) ) }
            when('room'){ $self->change_room($argument) } # all characters are supported in hash keys. Single quotes sometimes necessary.
            when('eval'){ eval $argument } # for the programmer :)
        }
        return 1
    }
    else{
        $self->room->command($command)
    }
}

sub retrieve_output{ # gets the current room output and sends it to self
    my $self = shift; say 'retrieving output!!!!!!!!!!!';
    my $html = room::htmlify( $self->room->output, $self->room->shell->prompt );
    $self->jsend( command=>'append', output=>$html );
}


1
