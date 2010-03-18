package Router::Simple::Declare::Class;
use strict;
use warnings;
use Router::Simple;

sub import {
    my $pkg = caller(0);
    my $router = Router::Simple->new();

    no strict 'refs';
    # functions
    for my $meth (qw/connect submapper resource/) {
        *{"${pkg}::${meth}"} = sub {
            $router->$meth(@_);
        };
    }
    # class methods
    for my $meth (qw/match as_string/) {
        *{"$pkg\::${meth}"} = sub {
            my $self = shift;
            $router->$meth(@_)
        };
    }
}

1;
__END__

=head1 NAME

Router::Simple::Declare::Class - declare router as class

=head1 SYNOPSIS

    package MyApp::Router;
    use Router::Simple::Declare::Class;
    connect '/' => {controller => 'Root', action => 'show'}, {method => 'GET'};
    connect '/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'}, {method => 'GET'};
    connect '/blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}', {controller => 'Blog', action => 'daily'}, {method => 'GET'};
    connect '/comment', {controller => 'Comment', 'action' => 'create'}, {method => 'POST'};

    submapper(path_prefix => '/account', class => 'Account')
        ->connect('/{action}');

    package main;

    sub {
        my $req = shift;
        my $q = MyApp::Router->match($req);
        ...
    }

=head1 DESCRIPTION

This class supports to write router class very easy.

=head1 EXPORTABLE FUNCTIONS

=over 4

=item connect($pattern, \%destination[, \%opts])

This function defines new route pattern.
See Router::Simple->connect() for more details.

=item YourRouter->match($req)

This function is not a function, just a class method.
You can call this method in your HTTP handler.

=back

=head1 SEE ALSO

L<Router::Simple>

=cut

