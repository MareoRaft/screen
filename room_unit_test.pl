use PerlProfile;

use room;

my $room = room->new( name=>uc('lion') );

my $str = 'hello there, ';
say room::subtract( $str.'doc.', $str );
