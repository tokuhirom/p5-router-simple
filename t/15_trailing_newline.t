use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new;
$r->connect('/', { controller => 'Root' });
$r->connect('/blog/{year:\d{4}}', { controller => 'Blog' }, { method => 'GET' });
$r->connect('/user/{name}', { controller => 'User' }, { host => 'example.com' });

my $env = sub { +{ PATH_INFO => $_[0], REQUEST_METHOD => $_[1] // 'GET', HTTP_HOST => $_[2] // 'example.com' } };

ok $r->match($env->('/')),          'match /';
ok !$r->match($env->("/\n")),       'do not match a trailing newline';
ok $r->match($env->('/blog/2014')), 'match /blog/2014';
ok !$r->match($env->("/blog/2014\n")), 'do not match a trailing newline after a placeholder';
ok !$r->match($env->('/blog/2014', "GET\n")), 'do not match a trailing newline in the method';
ok $r->match($env->('/user/foo')), 'match /user/foo';
ok !$r->match($env->('/user/foo', 'GET', "example.com\n")), 'do not match a trailing newline in the host';

done_testing;
