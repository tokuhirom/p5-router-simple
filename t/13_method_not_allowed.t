use strict;
use warnings;
use utf8;
use Test::More;
use Router::Simple;

my $r = Router::Simple->new();
$r->connect('/', {type => 1}, {method => 'GET'});
$r->connect('/', {type => 2}, {method => 'POST'});
$r->connect('/foo', {type => 3}, {method => 'GET'});

subtest 'Router::Simple' => sub {
    subtest 'GET /' => sub {
        my $p = $r->match({PATH_INFO => '/', REQUEST_METHOD => 'GET'});
        is($p->{type}, 1);
        ok(!$r->method_not_allowed());
    };
    subtest 'POST /' => sub {
        my $p = $r->match({PATH_INFO => '/', REQUEST_METHOD => 'POST'});
        is($p->{type}, 2);
        ok(!$r->method_not_allowed());
    };
    subtest 'PUT /' => sub {
        my $p = $r->match({PATH_INFO => '/', REQUEST_METHOD => 'PUT'});
        ok(!$p);
        ok($r->method_not_allowed());
    };
    subtest 'POST /foo' => sub {
        my $p = $r->match({PATH_INFO => '/foo', REQUEST_METHOD => 'POST'});
        ok(!$p);
        ok($r->method_not_allowed());
    };
    subtest 'GET /bar' => sub {
        my $p = $r->match({PATH_INFO => '/bar', REQUEST_METHOD => 'GET'});
        ok(!$p);
        ok(!$r->method_not_allowed());
    };
};

done_testing;

