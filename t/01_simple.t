use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->connect('home', '/' => {controller => 'Root', action => 'show'}, {method => 'GET', host => 'localhost'});
$r->connect('blog_monthly', '/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'}, {method => 'GET'});
$r->connect('/blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}', {controller => 'Blog', action => 'daily'}, {method => 'GET'});
$r->connect('/comment', {controller => 'Comment', 'action' => 'create'}, {method => 'POST'});
$r->connect('/', {controller => 'Root', 'action' => 'show_sub'}, {method => 'GET', host => 'sub.localhost'});
$r->connect(qr{^/belongs/([a-z]+)/([a-z]+)$}, {controller => 'May', action => 'show'});
$r->connect('/:controller/:action');

is_deeply(
    $r->match( +{ REQUEST_METHOD => 'GET', PATH_INFO => '/', HTTP_HOST => 'localhost'} ),
    {
        controller => 'Root',
        action     => 'show',
    }
);
is_deeply(
    $r->match( +{ PATH_INFO => '/blog/2010/03', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Blog',
        action     => 'monthly',
        year => 2010,
        month => '03'
    },
    'blog monthly'
);
is_deeply(
    $r->match( +{ PATH_INFO => '/blog/2010/03/04', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Blog',
        action     => 'daily',
        year => 2010, month => '03', day => '04',
    },
    'daily'
);
is_deeply(
    $r->match( +{ PATH_INFO => '/blog/2010/03', HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ) || undef,
    undef
);
is_deeply(
    $r->match( +{ PATH_INFO => '/comment', HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ) || undef,
    {
        controller => 'Comment',
        action     => 'create',
    }
);
is_deeply(
    $r->match( +{ PATH_INFO => '/', HTTP_HOST => 'sub.localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Root',
        action     => 'show_sub',
    }
);
is_deeply(
    $r->match( +{ PATH_INFO => '/belongs/to/us', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'May',
        action     => 'show',
        splat      => ['to', 'us'],
    }
);
is_deeply(
    $r->match( +{ PATH_INFO => '/foo/bar', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'foo',
        action     => 'bar',
    }
);

done_testing;
