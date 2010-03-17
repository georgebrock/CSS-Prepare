package CSS::Prepare::Property::Effects;

use Modern::Perl;
use CSS::Prepare::Property::Values;
use CSS::Prepare::Property::Expansions;



sub parse {
    my $self        = shift;
    my %declaration = @_;
    
    my $property = $declaration{'property'};
    my $value    = $declaration{'value'};
    my %canonical;
    my @errors;
    
    my $valid_property_or_error = sub {
            my $type  = shift;
            
            my $sub      = "is_${type}_value";
            my $is_valid = 0;
            
            eval {
                no strict 'refs';
                $is_valid = &$sub( $value );
            };
            
            if ( $is_valid ) {
                $canonical{ $property } = $value;
            }
            else {
                push @errors, {
                        error => "invalid ${type} property: ${value}"
                    };
            }
            return $is_valid;
        };
    
    foreach my $type qw( overflow visibility ) {
        &$valid_property_or_error( $type )
            if $type eq $property;
    }
    
    if ( $property eq 'clip' ) {
        %canonical = expand_clip( $value )
            if &$valid_property_or_error( 'clip' );
    }
    
    return \%canonical, \@errors;
}
sub output {
    my $block = shift;
    my @output;
    
    foreach my $property ( qw( overflow  visibility ) ) {
        my $value = $block->{ $property };
        
        push @output, "$property:$value;"
            if defined $value;
    }
    
    my @values;
    foreach my $direction ( qw( top right bottom left ) ) {
        my $property = "clip-rect-${direction}";
        my $value    = $block->{ $property };
        
        push @values, $value
            if defined $value;
    }
    if ( 4 == scalar @values ) {
        my $clipping = join ',', @values;
        push @output, "clip:rect($clipping);";
    }
    
    return @output;
}

1;
