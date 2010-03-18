use strict;
use warnings;
use Benchmark qw/:all/;

my ($hr, $rs);
{
    package HR;
    use HTTP::Router::Declare;
    $hr = router {
        # path and params
        match '/' => to { controller => 'Root', action => 'index' };

        # path, conditions, and params
        match '/home', { method => 'GET' }
            => to { controller => 'Home', action => 'show' };
        match '/date/{year}', { year => qr/^\d{4}$/ }
            => to { controller => 'Date', action => 'by_year' };

        # path, params, and nesting
        match '/account' => to { controller => 'Account' } => then {
            match '/login'  => to { action => 'login' };
            match '/logout' => to { action => 'logout' };
        };

        # path nesting
        match '/account' => then {
            match '/signup' => to { controller => 'Users', action => 'register' };
            match '/logout' => to { controller => 'Account', action => 'logout' };
        };

        # conditions nesting
        match { method => 'GET' } => then {
            match '/search' => to { controller => 'Items', action => 'search' };
            match '/tags'   => to { controller => 'Tags', action => 'index' };
        };

        # params nesting
        with { controller => 'Account' } => then {
            match '/login'  => to { action => 'login' };
            match '/logout' => to { action => 'logout' };
            match '/signup' => to { action => 'signup' };
        };

        # match only
        match '/{controller}/{action}/{id}.{format}';
        match '/{controller}/{action}/{id}';
    };
}
{
    package RS;
    use Router::Simple::Declare;
    $rs = router {
        # path and params
        connect '/' => { controller => 'Root', action => 'index' };

        # path, conditions, and params
        connect '/home', { controller => 'Home', action => 'show' }, { method => 'GET' };
        connect '/date/{year:\d{4}}',
            { controller => 'Date', action => 'by_year' };

        # path, params, and nesting
        submapper(path_prefix => '/account', controller => 'Account')
            ->connect('/login',  {action => 'login'})
            ->connect('/logout', {action => 'logout'});

        # path nesting
        submapper(path_prefix => '/account')
            ->connect('/signup',  {controller => 'User', action => 'register'})
            ->connect('/logout', {controller => 'Account', action => 'logout'});

        # conditions nesting
        submapper(method => 'GET')
            ->connect('/search' => {controller => 'Items', action => 'search'})
            ->connect('/tags'   => {controller => 'Tags',  action => 'index'});

        # params nesting
        submapper('controller' => 'Account')
            ->connect('/login', {action => 'login'})
            ->connect('/logout', {action => 'logout'})
            ->connect('/signup', {action => 'signup'});

        # match only
        connect '/{controller}/{action}/{id}.{format}';
        connect '/{controller}/{action}/{id}';
    };
}

cmpthese(
    -1, {
        'HTTP-Router' => sub {
            $hr->match('/account/login');
        },
        'Router-Simple' => sub {
            $rs->match('/account/login');
        },
    }
);

