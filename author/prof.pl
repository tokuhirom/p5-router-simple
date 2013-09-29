use strict;
use warnings;
use Router::Simple::Declare;

my $path = shift @ARGV || '/account/login';

my $rs = router {
    # path and params
    connect '/' => { controller => 'Root', action => 'index' };

    # path, conditions, and params
    connect '/home', { controller => 'Home', action => 'show' }, { method => 'GET' };
    connect '/date/{year:\d{4}}',
        { controller => 'Date', action => 'by_year' };

    # path, params, and nesting
    submapper('/account', { controller => 'Account' })
        ->connect('/login',  {action => 'login'})
        ->connect('/logout', {action => 'logout'});

    # path nesting
    submapper('/account')
        ->connect('/signup',  {controller => 'User', action => 'register'})
        ->connect('/logout', {controller => 'Account', action => 'logout'});

    # conditions nesting
    submapper('/', {}, { method => 'GET' })
        ->connect('/search' => {controller => 'Items', action => 'search'})
        ->connect('/tags'   => {controller => 'Tags',  action => 'index'});

    # params nesting
    submapper('/', { 'controller' => 'Account' })
        ->connect('/login', {action => 'login'})
        ->connect('/logout', {action => 'logout'})
        ->connect('/signup', {action => 'signup'});

    # match only
    connect '/{controller}/{action}/{id}.{format}';
    connect '/{controller}/{action}/{id}';
};

for my $i (0..10000) {
    $rs->match($path);
}

