package Router::Simple::Declare;
use strict;
use warnings;
use parent 'Exporter';
use Router::Simple;
use Carp ();

our @EXPORT = qw/router connect submapper resource/;

our $ROUTER;

sub router (&) {
    local $ROUTER = Router::Simple->new();
    $_[0]->();
    $ROUTER;
}

BEGIN {
    no strict 'refs';
    for my $meth (qw/connect submapper resource/) {
        *{$meth} = sub {
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            $ROUTER->$meth(@_);
        };
    }
}

1;
__END__

=head1 NAME

Router::Simple::Declare - declarative interface for Router::Simple

=head1 SYNOPSIS

    my $router = router {
        connect '/{controller}/{action}/{id}';

        submapper(class => 'Account', path_prefix => '/account')
            ->connect('/login', {action => 'login'})
            ->connect('/logout', {action => 'logout'});

        resource('Article', 'article', {collection_name => 'articles'});
    };

=head1 DESCRIPTION

Easy way to declare router object.

=head1 USAGE

look the SYNOPSIS.see L<Router::Simple> for more details.

=head1 SEE ALSO

L<Router::Simple>

=cut
