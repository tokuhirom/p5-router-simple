use strict;
use warnings;
use Router::Simple;
use Test::More;
use Test::Requires 'HTTP::Request';

my $r = Router::Simple->new();
$r->connect('/' => sub {
    'ok'
});

{
    my $res = $r->match( HTTP::Request->new( GET => 'http://localhost/' ) );
    ok $res->{code};
}
{
    my $res = $r->match( +{
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/',
    });
    ok $res->{code}, 'psgi';
}

done_testing;

