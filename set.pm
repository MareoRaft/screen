package set; # We will create set objects, AND allow the user to treat arrays as sets if they want to.

use strict; use warnings;

##################################### HELPERS / USED ON ARRAYS ONLY #################################
sub slim_array{ #removes duplicate occurances of an element
	my @input = @_;
    if( $#input <= 0 ){ return @input }
    for my $i (0..$#input-1){
      for( my $j=$i+1; $j<=$#input; ++$j ){ if( $input[$i] eq $input[$j] ){ splice @input, $j--, 1 } }
    }
	return @input
}

################################################# NEW ###############################################
sub new{ # new should NOT take in the subject variable.  Sometimes we want a blank set!
	my $packagename = shift;
	my $array = shift // []; ##say '$array is '.$array; # DON'T CALL STRINGIFY HERE, INFINITE LOOP
	my @array = slim_array @$array; #say '@array is '."@array"; # here we receive a NEW array
	bless [ @array ] => $packagename;
}

sub slim{ # slim should be called on sets only
	my $set = shift;
	if( $#$set <= 0 ){ return $set }
    for my $i (0..$#$set-1){
      for( my $j=$i+1; $j<=$#$set; ++$j ){ if( $$set[$i] eq $$set[$j] ){ splice @$set, $j--, 1 } }
    }
	return $set
}

# setify: if 1st input is a set ref, returns it.
# otherwise, if the first input is 'set', takes the rest of @_ and makes a set out of it, then returns it.
sub setify{
	my $subject = shift // $_;
	#say 'ref of first input is '.ref $subject;
	#say 'first input is '.$subject;
	if( ref $subject eq __PACKAGE__ ){ return $subject }
	elsif( ref $subject eq 'ARRAY' ){ return set->new($subject) }
	else{ die 'Function must receive a '.__PACKAGE__.' object or an ARRAY reference.' }
}

sub copy{
	my $set = setify shift;
	return set->new($set)
}
*clone = \&copy;

sub elements{
	my $set = setify shift;
	return @$set
}
*members = *els = *arr = *array = \&elements;

sub magnitude{
	my $set = setify shift;
	return my $magnitude = $set->elements
}
*size = *mag = \&magnitude;

use overload
	'""' => \&stringify,
	'+' => \&union,
	'-' => \&minus,
	'==' => \&is_equivalent,
	'<=' => \&is_subset,
	'>=' => \&is_superset,
	'<' => \&is_strict_subset,
	'>' => \&is_strict_superset
;

sub stringify{
	my $set = setify shift;
	my @elements = $set->elements;
	my $s = '{ '; $s .= shift @elements if @elements; foreach (@elements){ $s.=", $_" }; $s.=' }';
	return $s
}

# this is used for all functions who can take in N sets as input
sub repeat_operation{ # they are UNION, ADD, SYM_MINUS, etc...
	my $operation = shift;
	my $set = setify shift;
		foreach (@_){ my $nextset = setify $_; eval '$set = $set->'.$operation.'($nextset)' }
	return $set
}
*repeat_op = \&repeat_operation;

sub contains_element{
	my $set = setify shift;
	my $element = shift; #say 'element is '.$element;
	foreach ($set->elements){ if( $_ eq $element ){ return 1 } }
	return 0
}
*contains_el = \&contains_element;
sub is_element{
	my $element = shift;
	my $set = setify shift;
	return $set->contains_element($element)
}
*is_el = \&is_element;

sub add_elements{ # add ELEMENTS means that second input it ARRAY
	my $set = setify shift;
	my @elements = @_; #say "elements are @elements";
	foreach (@elements){ unless( $set->contains_element($_) ){ push @$set, $_ } }
	return $set
}
*add_els = *push_elements = *push_els = \&add_elements;
sub add_element{ # second input is a SCALAR
	my $set = setify shift;
	my ($element) = @_;
	return $set->add_elements($element)
}
*add_el = *push_element = *push_el = \&add_element;
sub add_pair{ # this returns the union, AND it alters setA to become that union
	my $setA = setify shift;
	my $setB = setify shift;
	return $setA->add_elements( $setB->elements )
}
sub add{
	repeat_op( 'add_pair', @_ )
}
*push = \&add;
sub union{
	my $setAcopy = (setify shift)->copy;
	return $setAcopy->add(@_)
}

sub remove_element{ # it is the nature of remove_ELEMENT that the second input is a SCALAR
	my $set = setify shift;
	my ($element) = @_;
	for my $i (0..$#$set){ if( $element eq $$set[$i] ){ splice @$set, $i, 1; last } }
	return $set
}
sub remove_elements{ # it is the nature of remove_ELEMENTS that the second input is an ARRAY
	my $set = setify shift;
	my @elements = @_;
	foreach (@elements){ $set = $set->remove_element($_) }
	return $set
}
sub remove{ # returns the difference, AND alters setA to become that difference
	my $setA = setify shift;
	my $setB = setify shift;
	return $setA->remove_elements( $setB->elements )
}
*subtract = \&remove; # returns the difference, AND alters setA to become that difference
sub minus{ # returns the subtraction
	my $setAcopy = (setify shift)->copy;
	my $setB = setify shift;
	return $setAcopy->remove($setB)
}

sub intersect_pair{
	my $setA = setify shift;
	my $setB = setify shift;
	my $intersection = set->new;
	foreach ($setA->elements){ #say "\t\t\t\treviewing element $_";
		if( is_element($_,$setB) ){ #say "\t\t\t\tit's in B!";
			$intersection->add_element($_)
		} #say "\t\t\t\tintersection is now $intersection";
	}
	return $intersection
}
sub intersect{
	repeat_op( 'intersect_pair', @_ )
}

sub sym_minus_pair{
	my $setA = setify shift; #say "\t\tsetA is $setA";
	my $setB = setify shift; #say "\t\tsetB is $setB";
	#say "\t\t\tsetA union B is".$setA->union($setB);
	#say "\t\t\tsetA intersect B is".$setA->intersect($setB);
	return $setA->union($setB)->remove( $setA->intersect($setB) )
}
sub sym_minus{
	repeat_op( 'sym_minus_pair', @_ )
}
*sym_diff = *symmetric_diff = *sym_difference = *symmetric_difference = *symmetric_minus = \&sym_minus;

sub is_subset{
	my $setA = setify shift;
	my $setB = setify shift;
 	foreach ($setA->elements){ unless( is_element($_,$setB) ){ return 0 } }
 	return 1
}
*subset = *is_contained_in = *is_contained = \&is_subset;
sub is_strict_subset{
	my $setA = setify shift;
	my $setB = setify shift;
	return ( $setA->magnitude < $setB->magnitude and $setA->is_subset($setB) )
}
*strict_subset = *is_strictly_contained_in = *is_strictly_contained = \&is_strict_subset;
sub is_superset{
	my $setA = setify shift;
	my $setB = setify shift;
	return $setB->is_subset($setA)
}
*superset = *is_containing = *contains = \&is_superset;
sub is_equivalent{
	my $setA = setify shift;
	my $setB = setify shift;
	return ( $setA->magnitude == $setB->magnitude and $setA->is_subset($setB) and $setB->is_subset($setA) )
}
*is_equal = \&is_equivalent;

sub is_empty{
	my $set = setify shift;
	return ( $set->magnitude == 0 )
}
sub empty{
	my $set = shift; # this works for both arrays and sets.  We do NOT want to setify an array because we
	# are not returning anything.  Instead, we are modifying the original through the reference.
	@$set = ()
}

################################ STANDARD ARRAY OPS DUPLICATED FOR SETS ###############################
sub unshift{
	my $set = setify shift;
	my @input = slim_array @_;
	$set->remove_elements(@input);
	unshift @$set, @input;
	return $set
}
sub pop{
	my $set = setify shift;
	return pop @$set
}
sub shift{ # this function must be last. once 'shift' is defined (at end of this function), all following 'shift' in this module are ambiguous
	my $set = setify shift;
	return shift @$set
}

1
