use strict;
use warnings;
use Router::Simple;
use Test::More;
use Test::Requires 'HTTP::Request';

my $r = Router::Simple->new();
$r->submapper(path_prefix => '/account', controller => 'Account')
      ->connect('/login', {action => 'login'})
      ->connect('/logout', {action => 'logout'});
$r->submapper('/entry/{id:[0-9]+}', controller => 'Entry')
      ->connect('/show', {action => 'show'})
      ->connect('/edit', {action => 'edit'});

is_deeply(
    $r->match( HTTP::Request->new( GET => 'http://localhost/account/login' ) ) || undef,
    {
        controller => 'Account',
        action     => 'login',
        args       => {},
    }
);
is_deeply(
    $r->match( HTTP::Request->new( GET => 'http://localhost/entry/49/edit' ) ) || undef,
    {
        controller => 'Entry',
        action     => 'edit',
        args       => {id=>49},
    }
);

done_testing;
