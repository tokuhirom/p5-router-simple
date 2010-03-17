package Router::Simple::Declare::Class;
use strict;
use warnings;
use parent 'Exporter';
our @EXPORT = qw/connect/;
use Router::Simple;

sub import {
    my $pkg = caller(0);
    my $router = Router::Simple->new();

    no strict 'refs';
    *{"$pkg\::connect"} = sub {
        $router->connect(@_);
    };
    *{"$pkg\::match"} = sub {
        my $self = shift; $router->match(@_)
    };
}

1;
