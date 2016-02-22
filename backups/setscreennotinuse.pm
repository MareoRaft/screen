# THIS SET IS FROZEN IN TIME, SERVING SCREEN.

package set;

use strict; use warnings;


sub new{
	my $packagename = shift;
	my @elements = @_;
	bless [ @elements ] => $packagename;
}

sub copy{
	my $set = shift;
	return set->new($set->elements)
}
*clone = \&copy;

sub elements{
	my $set = shift;
	return @$set
}
*array = \&elements;

sub magnitude{
	my $set = shift;
	return my $magnitude = $set->elements
}
*size = \&magnitude;

use overload
	'""' => \&stringify,
	'+' => \&union,
	'-' => \&minus;

sub stringify{
	my $set = shift;
	my @elements = $set->elements;
	my $s = '{ '; $s .= shift @elements; foreach (@elements){ $s.=", $_" }; $s.=' }';
	return $s
}

sub contains_element{
	my $set = shift;
	my ($element) = @_;
	foreach ($set->elements){ if( $_ eq $element ){ return 1 } }
	return 0
}
*contains_el = \&contains_element;
sub is_element{
	my ($element,$set) = @_;
	return $set->contains_element($element)
}
*is_el = \&is_element;

sub add_elements{
	my $set = shift;
	my @elements = @_;
	foreach (@elements){ unless( $set->contains_element($_) ){ push @$set, $_ } }
	return $set
}
sub add_element{
	my $set = shift;
	my ($element) = @_;
	return $set->add_elements($element)
}
sub add{ # this returns the union, AND it alters setA to become that union
	my $setA = shift;
	my $setB = shift;
	return $setA->add_elements( $setB->elements )
}
sub union{
	my $setAcopy = shift->copy;
	my $setB = shift;
	return $setAcopy->add($setB)
}

sub remove_element{
	my $set = shift;
	my ($element) = @_;
	my $lastindex = $set->magnitude - 1;
	for my $i (0..$lastindex){ if( $element eq $$set[$i] ){ splice @$set, $i, 1; last } }
	return $set
}
sub remove_elements{
	my $set = shift;
	my @elements = @_;
	foreach (@elements){ $set = $set->remove_element($_) }
	return $set
}
sub remove{ # returns the difference, AND alters setA to become that difference
	my $setA = shift;
	my $setB = shift;
	return $setA->remove_elements( $setB->elements )
}
*subtract = \&remove; # returns the difference, AND alters setA to become that difference
sub minus{ # returns the subtraction
	my $setAcopy = shift->copy;
	my $setB = shift;
	return $setAcopy->remove($setB)
}

sub intersect{
	my $setA = shift;
	my $setB = shift;
	my $intersection = set->new;
	foreach ($setA->elements){ if( is_element($_,$setB) ){ $intersection->add_element($_) } }
	return $intersection
}

sub symMinus{
	my $setA = shift;
	my $setB = shift;
	return $setA->union($setB)->remove( $setA->intersect($setB) )
}

sub is_subset{
	my $setA = shift;
	my $setB = shift;
 	foreach ($setA->elements){ unless( is_element($_,$setB) ){ return 0 } }
 	return 1
}
*subset = *is_contained_in = *is_contained = \&is_subset;
sub is_superset{
	my $setA = shift;
	my $setB = shift;
 	return $setB->is_subset($setA)
}
*superset = *is_containing = *contains = \&is_superset;


1
