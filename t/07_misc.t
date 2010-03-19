use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->connect('/' => sub {
    'ok'
});

{
    my $res = $r->match(
        +{
            REQUEST_METHOD => 'GET',
            HTTP_HOST      => 'localhost',
            'PATH_INFO'    => '/'
        }
    );
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

