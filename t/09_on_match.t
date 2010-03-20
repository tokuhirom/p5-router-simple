use strict;
use warnings;
use Router::Simple;
use Test::More;
 
my $r = Router::Simple->new()
            ->connect('/hi/:user', { action => 'hello_who' },
                      { on_match => sub { my($path, $m) = @_; return $m->{user} ne 'foo' } })
            ->connect('/hi/{user:.*}', { action => 'hi' } );
 
is_deeply(
    $r->match('/hi/miyagawa'),
    {
        action => 'hello_who',
        user   => 'miyagawa',
    }
);
 
is_deeply(
    $r->match('/hi/foo'),
    {
        action => 'hi',
        user => 'foo',
    }
);
 
done_testing;
