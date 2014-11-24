use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->submapper('/account', {controller => 'Account'})
      ->connect('/login', {action => 'login'})
      ->connect('/logout', {action => 'logout'})
      ->submapper('/profile') # nested submapper
          ->connect('/show', {action => 'profile_show'})
;

$r->submapper('/entry/{id:[0-9]+}', {controller => 'Entry'})
      ->connect('/show', {action => 'show'})
      ->connect('/edit', {action => 'edit'});

is_deeply(
    $r->match( +{ PATH_INFO => '/account/login', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Account',
        action     => 'login',
    }
);

is_deeply(
    $r->match( +{ PATH_INFO => '/account/profile/show', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Account',
        action     => 'profile_show',
    }
);

is_deeply(
    $r->match( +{ PATH_INFO => '/entry/49/edit', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Entry',
        action     => 'edit',
        id=>49,
    }
);

done_testing;
