use strict;
use warnings;
use Benchmark qw/:all/;
use Data::Dumper;
use Plack::Request;

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
            match '/logout' => to { action => 'logout' };
            match '/login'  => to { action => 'login' };
        };
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
        submapper('/account', {controller => 'Account'})
            ->connect('/logout', {action => 'logout'})
            ->connect('/login',  {action => 'login'});
    };
}
{
    package HD;
    use HTTPx::Dispatcher;

    # path and params
    connect '/' => { controller => 'Root', action => 'index' };

    # path, conditions, and params
    connect '/home', { controller => 'Home', action => 'show' }, { method => 'GET' };
    connect '/date/{year:\d{4}}',
        { controller => 'Date', action => 'by_year' };

    # path, params, and nesting
    connect '/account/logout' => {controller => 'Account', action => 'logout'};
    connect '/account/login' => {controller => 'Account', action => 'login'};
}

#arn Dumper($hr->match('/account/login'));
#arn Dumper($rs->match('/account/login'));

my $req  = Plack::Request->new({ PATH_INFO => '/account/login' });
my $req2 = Plack::Request->new({ PATH_INFO => '/date/2000' });

cmpthese(
    -1, {
        'HTTP-Router' => sub {
            $hr->match('/account/login');
            $hr->match('/date/2000');
        },
        'Router-Simple' => sub {
            $rs->match('/account/login');
            $rs->match('/date/2000');
        },
        'HTTPx-Dispatcher' => sub {
            HD->match($req);
            HD->match($req2);
        },
    }
);

