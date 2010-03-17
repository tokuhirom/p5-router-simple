use strict;
use warnings;
use Router::Simple;
use Test::More;
use Test::Requires 'HTTP::Request';

my $r = Router::Simple->new();
my $s = $r->submapper(path_prefix => '/account', controller => 'Account');
$s->connect('/login', {action => 'login'});
$s->connect('/logout', {action => 'logout'});

is_deeply(
    $r->match( HTTP::Request->new( GET => 'http://localhost/account/login' ) ) || undef,
    {
        controller => 'Account',
        action     => 'login',
        args       => {},
    }
);

done_testing;
