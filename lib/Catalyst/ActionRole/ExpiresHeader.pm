package Catalyst::ActionRole::ExpiresHeader;

use Moose::Role;
use HTTP::Date qw(time2str);
use namespace::autoclean;

our $VERSION = '0.01';

=encoding utf8

=head1 NAME

Catalyst::ActionRole::ExpiresHeader - Set default Expires header for actions   

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    BEGIN { extends 'Catalyst::Controller'; }

    with 'Catalyst::TraitFor::Controller::ActionRole' => {
        action_roles => ['ExpiresHeader'],
    };

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

=head1 AUTHOR

Alex J. G. Burzyński, C<< <ajgb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-actionrole-expiresheader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-ActionRole-ExpiresHeader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alex J. G. Burzyński.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

around 'execute' => sub {
    my $orig = shift;
    my $self = shift;
    my ($controller, $c, @args) = @_;

    my $action = $self->$orig($controller, $c, @args);

    if ( my $expires_attr = $c->action->attributes->{Expires} ) {
        my $expires = $self->_parse_Expires_attr( $expires_attr->[0] );
        unless ( $c->response->header('Expires') ) {
            $c->response->header( 
                Expires =>
                    $expires =~ /^\d+$/ ? time2str( $expires ) : $expires
            );
        }
    }

    return $action;
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
1; # End of Catalyst::ActionRole::ExpiresHeader

