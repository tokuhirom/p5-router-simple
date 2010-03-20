use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->connect(
    'home',
    '/' => { controller => 'Root', action => 'show' },
    {
        method   => 'GET',
        host     => 'localhost',
        on_match => sub { 1 }
    }
);
my ( $ret, $route ) = $r->routematch(
    { HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET', PATH_INFO => '/' }
);
is_deeply $route->method, ['GET'];
is_deeply $route->host, 'localhost';
is ref($route->on_match), 'CODE';

done_testing;

