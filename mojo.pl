package mojo;
# DON'T USE MORBO    DON'T USE MORBO
use Mojolicious::Lite; # includes strict, warnings, and a bunch of Mojo packages
use feature 'switch';
use helpers;
use self; # adds extra capabilities to '$self' (a Mojolicious::Controller)

################################################# HYPNOTOAD ###############################################
# if using hypnotoad, configure the port
app->config(hypnotoad => {listen => ['http://*:8000']});

####################################################### MOJO ######################################################
get '/' => sub{
	my $self = shift; # self is a mojolicious controller
	$self->res->headers->cache_control('max-age=1, no-cache'); # client side caching
	$self->render( template=>'index', format=>'html', handler=>'ep' ); # the format (html) and the handler (ep) are automatically detected and do not NEED to be specified here
};

get '/javascript' => sub{
	my $self = shift;
	$self->res->headers->cache_control('max-age=1, no-cache');
	$self->render( template=>'javascript', format=>'js', handler=>'ep' );
};

websocket '/websocket' => sub{ # when JS opens ws connection, this is kicked off
	my $self = shift;
	Mojo::IOLoop->stream($self->tx->connection)->timeout(60*30); # the time in seconds that the stream is innactive before being automatically closed
	# see if we are already in a room. if not, get a room:
	if( defined $self->roomname ){
		say 'self already has roomname: '.$self->roomname.'.'; # for debugging only.
		#if( exists $room::nametoroom{$self->roomname} ){ say 'and the room exists!!!'}else{ say q(...but the room doesn't exist.) } # for debugging only
		$self->join_room($self->roomname);
	}
	else{
		say 'joining random room...'; $self->join_room(room::rand_name); say 'survived random room setting.'
	};
	# what to do when receiving commands:
	$self->on(
		json => sub{
			my ($self,$ballref) = @_; my %ball = %$ballref;
			given($ball{command}) {
				when('command'){
					$self->command($ball{input})
				}
			}
		}
	);
	$self->on(
		close => sub{ say 'websocket is closing..............';
			my ($self) = @_;
			$self->leave_room;
		}
	);
};

app->renderer->cache(Mojo::Cache->new('max_keys'=>1)); # tell mojolicious to avoid caching (but, this only works when the same page isn't being fetched twice in a row.)
app->secrets(['if you do not belong here, screem!']);
app->start; # this must be the last line, because mojo.pl must return an application object.

# NO CODE ALLOWED HERE (see app->start above)
