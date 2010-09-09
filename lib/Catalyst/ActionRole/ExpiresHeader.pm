package Catalyst::ActionRole::ExpiresHeader;
# ABSTRACT: Set default Expires header for actions

use strict;
use Moose::Role;
use HTTP::Date qw(time2str);

after 'execute' => sub {
    my $self = shift;
    my ($controller, $c, @args) = @_;

    if ( my $expires_attr = $c->action->attributes->{Expires} ) {
        my $expires = $self->_parse_Expires_attr( $expires_attr->[0] );
        unless ( $c->response->header('Expires') ) {
            $c->response->header(
                Expires =>
                    $expires =~ /^\d+$/ ? time2str( $expires ) : $expires
            );
        }
    }
};

{
    my (%mult) = (
        's' => 1,
        'm' => 60,
        'h' => 60*60,
        'd' => 60*60*24,
        'M' => 60*60*24*30,
        'y' => 60*60*24*365
    );

    sub _parse_Expires_attr {
        my ($self, $time) = @_;

        # below code is copied from CGI::Util for compability with CGI::Cookie
        my($offset);
        if (!$time || (lc($time) eq 'now')) {
          $offset = 0;
        } elsif ($time=~/^\d+/) {
          return $time;
        } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
          $offset = ($mult{$2} || 1)*$1;
        } else {
          return $time;
        }
        return (time+$offset);
    }
}

no Moose::Role;

=head1 SYNOPSIS

    package MyApp::Controller::Foo;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::ActionRole' }

    __PACKAGE__->config(
        action_roles => [qw( ExpiresHeader )],
    );

    sub expire_in_one_day : Local Expires('+1d') { ... }

    sub already_expired : Local Expires('-1d') { ... }

=head1 DESCRIPTION

Provides a ActionRole to set HTTP Expires header for actions, which will be
set unless Expires header was already set.

Argument syntax matches the C<-expires> from
L<CGI/CREATING_A_STANDARD_HTTP_HEADER:>.

=head1 SEE ALSO

Take a look at L<Catalyst::ActionRole::NotCacheableHeaders> to make your
action not cachable by default.

=cut

1; # End of Catalyst::ActionRole::ExpiresHeader

