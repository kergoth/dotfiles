
# XXX XXX XXX  THIS IS A NEW FILE XXX XXX XXX

#
# @FILE_EXT@
#
# Developed by @AUTHOR@ <@EMAIL@>
# Copyright (c) @YEAR@ @COMPANY@
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# @DATE@ - created
#

# $Platon$

package @FILE@;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

@ISA     = qw(Exporter);
@EXPORT  = qw( );
$VERSION = '0.1';

sub new
{ #{{{
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {};

    bless $self, $class;
    $self->set(@_) if @_;

    return $self;
} # }}}

1;

__END__

=head1 NAME

@FILE@ - <<<description of module>>>

=head1 SYNOPSIS

  use @FILE@;

  my $xxx = new @FILE@;

=head1 DESCRIPTION

The @FILE@ module allows you ...
<<<your description here>>>

=head2 EXPORT

<<here describe exported methods>>>

=head1 SEE ALSO

=head1 AUTHORS

@AUTHOR@, <@EMAIL@>

=cut

# vim: ts=4
# vim600: fdm=marker fdl=0 fdc=3

