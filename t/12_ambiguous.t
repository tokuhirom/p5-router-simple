use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->connect('/', {}, {method => 'GET', host => 'localhost'});

isnt($r->match( +{ HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ), undef);

done_testing;
