use strict;
use warnings;
use Router::Simple;
use Test::More;
use Test::Requires 'HTTP::Request';

my $r = Router::Simple->new();
$r->resource('Article', 'articles');

is_deeply(
    $r->match( HTTP::Request->new( POST => 'http://localhost/articles' ) ) || undef,
    {
        controller => 'Article',
        action     => 'create',
        args       => {},
    }
);
is_deeply(
    mr(GET => 'http://localhost/articles'),
    {
        controller => 'Article',
        action     => 'index',
        args       => {},
    }
);
is_deeply(
    mr(GET => 'http://localhost/articles.rss'),
    {
        controller => 'Article',
        action     => 'index',
        args       => {format => 'rss'},
    }
);
is_deeply(
    mr(GET => 'http://localhost/articles/new'),
    {
        controller => 'Article',
        action     => 'new',
        args       => {},
    }
);
is_deeply(
    mr(GET => 'http://localhost/articles/new.rss'),
    {
        controller => 'Article',
        action     => 'new',
        args       => {format => 'rss'},
    }
);
is_deeply(
    mr(PUT => 'http://localhost/articles/1'),
    {
        controller => 'Article',
        action     => 'update',
        args       => {id => 1},
    }
);
is_deeply(
    mr(DELETE => 'http://localhost/articles/1'),
    {
        controller => 'Article',
        action     => 'delete',
        args       => {id => 1},
    }
);
is_deeply(
    mr(GET => 'http://localhost/articles/1/edit'),
    {
        controller => 'Article',
        action     => 'edit',
        args       => {id => 1},
    },
    'edit'
);
is_deeply(
    mr(GET => 'http://localhost/articles/1.rss/edit'),
    {
        controller => 'Article',
        action     => 'edit',
        args       => {id => 1, format => 'rss'},
    },
    'edit,format'
);
is_deeply(
    mr(GET => 'http://localhost/articles/1'),
    {
        controller => 'Article',
        action     => 'show',
        args       => {id => 1},
    }
);
is_deeply(
    mr(GET => 'http://localhost/articles/4.rss'),
    {
        controller => 'Article',
        action     => 'show',
        args       => {id => 4, format => 'rss'},
    }
);

done_testing;

sub mr { $r->match( HTTP::Request->new( @_ ) ) }

