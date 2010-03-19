use strict;
use warnings;
use Test::More;

{
    package MyDispatcher;
    use Router::Simple::Declare::Class;

    connect '/' => {controller => 'Root', action => 'show'}, {method => 'GET'};
    connect '/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'}, {method => 'GET'};
    connect '/blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}', {controller => 'Blog', action => 'daily'}, {method => 'GET'};
    connect '/comment', {controller => 'Comment', 'action' => 'create'}, {method => 'POST'};

    submapper(path_prefix => '/account', controller => 'Account')
        ->connect('/{action}');

}

is_deeply(
    MyDispatcher->match( +{ PATH_INFO => '/', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Root',
        action     => 'show',
        args       => {},
    }
);
is_deeply(
    MyDispatcher->match( +{ PATH_INFO => '/blog/2010/03', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Blog',
        action     => 'monthly',
        args       => {year => 2010, month => '03'},
    }
);
is_deeply(
    MyDispatcher->match( +{ PATH_INFO => '/blog/2010/03/04', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Blog',
        action     => 'daily',
        args       => {year => 2010, month => '03', day => '04'},
    },
    'daily'
);
is_deeply(
    MyDispatcher->match( +{ PATH_INFO => '/blog/2010/03', HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ) || undef,
    undef
);
is_deeply(
    MyDispatcher->match( +{ PATH_INFO => '/comment', HTTP_HOST => 'localhost', REQUEST_METHOD => 'POST' } ) || undef,
    {
        controller => 'Comment',
        action     => 'create',
        args       => {},
    }
);
diag(MyDispatcher->as_string());
is_deeply(
    MyDispatcher->match( +{ PATH_INFO => '/account/login', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Account',
        action     => 'login',
        args       => {},
    }
);
is_deeply(
    MyDispatcher->match( +{ PATH_INFO => '/account/logout', HTTP_HOST => 'localhost', REQUEST_METHOD => 'GET' } ) || undef,
    {
        controller => 'Account',
        action     => 'logout',
        args       => {},
    }
);

done_testing;
