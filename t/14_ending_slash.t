use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new({ directory_slash => 1 });
$r->connect('blog_monthly', '/blog/{year}/{month}/', {controller => 'Blog', action => 'monthly'}, {method => 'GET'});
$r->connect('/blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}/', {controller => 'Blog', action => 'daily'}, {method => 'GET'});
$r->connect('/comment/', {controller => 'Comment', 'action' => 'create'}, {method => 'POST'});
$r->connect('/:controller/:action/');

foreach my $es ('', '/') {
    is_deeply(
        $r->match( +{ PATH_INFO => '/blog/2010/03' . $es, HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
        {
            controller => 'Blog',
            action     => 'monthly',
            year => 2010,
            month => '03'
        },
        'blog monthly'
    );
    is_deeply(
        $r->match( +{ PATH_INFO => '/blog/2010/03/04' . $es, HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
        {
            controller => 'Blog',
            action     => 'daily',
            year => 2010, month => '03', day => '04',
        },
        'daily'
    );
    is_deeply(
        $r->match( +{ PATH_INFO => '/blog/2010/03' . $es, HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ) || undef,
        undef
    );
    is_deeply(
        $r->match( +{ PATH_INFO => '/comment' . $es, HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ) || undef,
        {
            controller => 'Comment',
            action     => 'create',
        }
    );
    is_deeply(
        $r->match( +{ PATH_INFO => '/foo/bar' . $es, HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
        {
            controller => 'foo',
            action     => 'bar',
        }
    );
}

done_testing;
