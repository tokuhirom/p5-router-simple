use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->connect('/blog/{year:(?:199\d|20\d{2})}/{month:(?:0?[1-9]|1[0-2])}' => {controller => 'Root', action => 'monthly'});

is_deeply(
    $r->match('/blog/2010/08'),
    {
        controller => 'Root',
        action     => 'monthly',
        year       => '2010',
        month      => '08',
    }
);
is($r->match('/blog/1989/08'), undef, "strictly regexp check #1");
is($r->match('/blog/2010/13'), undef, "strictly regexp check #2");

done_testing;
