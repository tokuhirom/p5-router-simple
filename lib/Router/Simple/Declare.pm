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

=head1 SYNOPSIS

    my $router = router {
        match '/{controller}/{action}/{id}';
    };
