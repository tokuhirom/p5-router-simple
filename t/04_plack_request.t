use strict;
use warnings;
use Router::Simple;
use Test::More;
use Test::Requires 'Plack::Request';

my $r = Router::Simple->new();
$r->connect('/' => {controller => 'Root', action => 'show'}, {method => 'GET'});
$r->connect('/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'}, {method => 'GET'});
$r->connect('/blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}', {controller => 'Blog', action => 'daily'}, {method => 'GET'});
$r->connect('/comment', {controller => 'Comment', 'action' => 'create'}, {method => 'POST'});

is_deeply(
    $r->match(
        Plack::Request->new(
            +{
                REQUEST_METHOD => 'GET',
                PATH_INFO      => '/blog/2010/03',
            }
        )
      )
      || undef,
    {
        controller => 'Blog',
        action     => 'monthly',
        args       => { year => 2010, month => '03' },
    }
);

done_testing;
