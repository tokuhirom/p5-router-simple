use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->connect('/' => {controller => 'Root', action => 'show'});
$r->connect('/p' => {controller => 'Root', action => 'p'});

is_deeply(
    $r->match( +{ PATH_INFO => '/', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Root',
        action     => 'show',
    }
);

is_deeply(
    $r->match( +{ PATH_INFO => '/p', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Root',
        action     => 'p',
    }
);

done_testing;

