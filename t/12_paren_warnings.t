use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new();
$r->connect('home', '/' => {controller => 'Root', action => 'show'}, {method => 'GET', host => 'localhost'});
$r->connect('blog_monthly', '/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'}, {method => 'GET'});
$r->connect('/blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}', {controller => 'Blog', action => 'daily'}, {method => 'GET'});
$r->connect('/regexp/{year:(\d{1,4})}/{month:(\d{2})}/{day:(\d\d)}', {controller => 'Blog', action => 'daily'}, {method => 'GET'});
$r->connect('/comment', {controller => 'Comment', 'action' => 'create'}, {method => 'POST'});
$r->connect('/', {controller => 'Root', 'action' => 'show_sub'}, {method => 'GET', host => 'sub.localhost'});
$r->connect(qr{^/belongs/([a-z]+)/([a-z]+)$}, {controller => 'May', action => 'show'});
$r->connect('/:controller/:action');

eval {
    $r->match( +{ PATH_INFO => '/regexp/2010/03/04', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } )
};
like($@, qr/pattern/);

done_testing;
