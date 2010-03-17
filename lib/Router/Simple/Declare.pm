package Router::Simple::Declare;
use strict;
use warnings;
use parent 'Exporter';
use Router::Simple;

our @EXPORT = qw/router connect/;

our $ROUTER;

sub router (&) {
    local $ROUTER = Router::Simple->new();
    $_[0]->();
    $ROUTER;
}

sub connect($$;$) { $ROUTER->connect(@_) }

1;
__END__

=head1 NAME

Router::Simple::Declare - declarative interface for Router::Simple

=head1 SYNOPSIS

    my $router = router {
        connect '/{controller}/{action}/{id}';
    };

=head1 DESCRIPTION

Easy way to declare router object.

=head1 USAGE

look the SYNOPSIS.see L<Router::Simple> for more details.

=head1 SEE ALSO

L<Router::Simple>

=cut
