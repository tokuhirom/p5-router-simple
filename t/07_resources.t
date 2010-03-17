use strict;
use warnings;
use Router::Simple;
use Test::More;
use Test::Requires 'HTTP::Request';

my $r = Router::Simple->new();
$r->resource('Article', 'article');

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

# -------------------------------------------------------------------------

diag($r->as_string());
is $r->url_for( 'articles' ), '/articles', 'url_for';
is $r->url_for( 'formatted_articles', {format => 'json'} ), '/articles.json';
is $r->url_for( 'new_articles'), '/articles/new';
is $r->url_for( 'formatted_new_articles', {format => 'json'}), '/articles/new.json';
is $r->url_for( 'formatted_edit_articles', {id => 3, format => 'json'}), '/articles/3.json/edit';
is $r->url_for( 'edit_articles', {id => 3}), '/articles/3/edit';
is $r->url_for( 'formatted_article', {id => 3, format => 'json'}), '/articles/3.json', 'formatted_article';
is $r->url_for( 'article', {id => 3} ), '/articles/3', 'url_for';

done_testing;

sub mr { $r->match( HTTP::Request->new( @_ ) ) }

