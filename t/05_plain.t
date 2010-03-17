use strict;
use warnings;
use Router::Simple;
use Test::More;
use Test::Requires 'HTTP::Request';

my $r = Router::Simple->new();
$r->connect('/' => {controller => 'Root', action => 'show'});
$r->connect('/p' => {controller => 'Root', action => 'p'});

is_deeply(
    $r->match( HTTP::Request->new( GET => 'http://localhost/' ) ) || undef,
    {
        controller => 'Root',
        action     => 'show',
        args       => {},
    }
);

is_deeply(
    $r->match( HTTP::Request->new( GET => 'http://localhost/p' ) ) || undef,
    {
        controller => 'Root',
        action     => 'p',
        args       => {},
    }
);

done_testing;

