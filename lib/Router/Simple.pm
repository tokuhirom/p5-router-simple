package Router::Simple;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.17';
use Router::Simple::SubMapper;
use Router::Simple::Route;
use List::Util qw/max/;
use Carp ();

use Class::Accessor::Lite 0.05 (
    new => 1,
    ro => [qw(routes directory_slash)],
);

our $_METHOD_NOT_ALLOWED;

sub connect {
    my $self = shift;

    if ($self->{directory_slash}) {
        # connect([$name, ]$pattern[, \%dest[, \%opt]])
        if (@_ == 1 || ref $_[1]) {
            unshift(@_, undef);
        }

        # \%opt
        $_[3] ||= {};
        $_[3]->{directory_slash} = 1;
    }

    my $route = Router::Simple::Route->new(@_);
    push @{ $self->{routes} }, $route;
    return $self;
}

sub submapper {
    my ($self, $pattern, $dest, $opt) = @_;
    return Router::Simple::SubMapper->new(
        parent  => $self,
        pattern => $pattern,
        dest    => $dest || +{},
        opt     => $opt || +{},
    );
}

sub _match {
    my ($self, $env) = @_;

    if (ref $env) {
        # "I think there was a discussion about that a while ago and it is up to apps to deal with empty PATH_INFO as root / iirc"
        # -- by @miyagawa
        #
        # see http://blog.64p.org/entry/2012/10/05/132354
        if ($env->{PATH_INFO} eq '') {
            $env->{PATH_INFO} = '/';
        }
    } else {
        $env = +{ PATH_INFO => $env }
    }

    local $_METHOD_NOT_ALLOWED;
    $self->{method_not_allowed} = 0;
    for my $route (@{$self->{routes}}) {
        my $match = $route->match($env);
        return ($match, $route) if $match;
    }
    $self->{method_not_allowed} = $_METHOD_NOT_ALLOWED;
    return undef; # not matched.
}

sub method_not_allowed {
    my $self = shift;
    $self->{method_not_allowed};
}

sub match {
    my ($self, $req) = @_;
    my ($match) = $self->_match($req);
    return $match;
}

sub routematch {
    my ($self, $req) = @_;
    return $self->_match($req);
}

sub as_string {
    my $self = shift;

    my $mn = max(map { $_->{name} ? length($_->{name}) : 0 } @{$self->{routes}});
    my $nn = max(map { $_->{method} ? length(join(",",@{$_->{method}})) : 0 } @{$self->{routes}});

    return join('', map {
        sprintf "%-${mn}s %-${nn}s %s\n", $_->{name}||'', join(',', @{$_->{method} || []}) || '', $_->{pattern}
    } @{$self->{routes}}) . "\n";
}

1;
__END__

=for stopwords DeNA

=encoding utf8

=head1 NAME

Router::Simple - simple HTTP router

=head1 SYNOPSIS

    use Router::Simple;

    my $router = Router::Simple->new();
    $router->connect('/', {controller => 'Root', action => 'show'});
    $router->connect('/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'});

    my $app = sub {
        my $env = shift;
        if (my $p = $router->match($env)) {
            # $p = { controller => 'Blog', action => 'monthly', ... }
        } else {
            [404, [], ['not found']];
        }
    };

=head1 DESCRIPTION

Router::Simple is a simple router class.

Its main purpose is to serve as a dispatcher for web applications.

Router::Simple can match against PSGI C<$env> directly, which means
it's easy to use with PSGI supporting web frameworks.

=head1 HOW TO WRITE A ROUTING RULE

=head2 plain string

    $router->connect( '/foo', { controller => 'Root', action => 'foo' } );

=head2 :name notation

    $router->connect( '/wiki/:page', { controller => 'WikiPage', action => 'show' } );
    ...
    $router->match('/wiki/john');
    # => {controller => 'WikiPage', action => 'show', page => 'john' }

':name' notation matches C<qr{([^/]+)}>, and it will be captured.

=head2 '*' notation

    $router->connect( '/download/*.*', { controller => 'Download', action => 'file' } );
    ...
    $router->match('/download/path/to/file.xml');
    # => {controller => 'Download', action => 'file', splat => ['path/to/file', 'xml'] }

'*' notation matches C<qr{(.+)}>. You will get the captured argument as
an array ref for the special key C<splat>.

=head2 '{year}' notation

    $router->connect( '/blog/{year}', { controller => 'Blog', action => 'yearly' } );
    ...
    $router->match('/blog/2010');
    # => {controller => 'Blog', action => 'yearly', year => 2010 }

'{year}' notation matches C<qr{([^/]+)}>, and it will be captured.  '{year}'
behaves the same was as ':year'.

=head2 '{year:[0-9]+}' notation

    $router->connect( '/blog/{year:[0-9]+}/{month:[0-9]{2}}', { controller => 'Blog', action => 'monthly' } );
    ...
    $router->match('/blog/2010/04');
    # => {controller => 'Blog', action => 'monthly', year => 2010, month => '04' }

You can specify regular expressions in named captures.

=head2 regexp

    $router->connect( qr{/blog/(\d+)/([0-9]{2})', { controller => 'Blog', action => 'monthly' } );
    ...
    $router->match('/blog/2010/04');
    # => {controller => 'Blog', action => 'monthly', splat => [2010, '04'] }

You can use Perl5's powerful regexp directly, and the captured values
are stored in the special key C<splat>.

=head1 METHODS

=over 4

=item my $router = Router::Simple->new();

Creates a new instance of Router::Simple.

=item $router->method_not_allowed() : Boolean

If the last attempt to match with C<< $router->match() >> was rejected because
the HTTP method was disallowed (as opposed to, say, not matching any routed
paths) this method returns true.

=item $router->connect([$name, ] $pattern, \%destination[, \%options])

Adds a new rule to $router.

    $router->connect( '/', { controller => 'Root', action => 'index' } );
    $router->connect( 'show_entry', '/blog/:id',
        { controller => 'Blog', action => 'show' } );
    $router->connect( '/blog/:id', { controller => 'Blog', action => 'show' } );
    $router->connect( '/comment', { controller => 'Comment', action => 'new_comment' }, {method => 'POST'} );

'connect' returns the router object, so 'connect' calls can be chained.

C<\%destination> will be used by I<match> method.

You can specify some optional things in C<\%options>. The current
version supports 'method', 'host', and 'on_match'.

=over 4

=item method

'method' is an ArrayRef[String] or String that matches B<REQUEST_METHOD> in $req.

=item host

'host' is a String or Regexp that matches B<HTTP_HOST> in $req.

=item on_match

    $r->connect(
        '/{controller}/{action}/{id}',
        {},
        {
            on_match => sub {
                my($env, $match) = @_;
                $match->{referer} = $env->{HTTP_REFERER};
                return 1;
            }
        }
    );

A function that evaluates the request. Its signature must be C<<
($environ, $match) => bool >>. It should return true if the match is
successful or false otherwise. The first argument is C<$env> which is
either a PSGI environment or a request path, depending on what you
pass to C<match> method; the second is the routing variables that
will be returned if the match succeeds.

The function can modify C<$env> (if it's a reference) and
C<$match> in place to affect which variables are returned. This allows
a wide range of transformations.

=back

=item C<< $router->submapper($path, [\%dest, [\%opt]]) >>

    $router->submapper('/entry/', {controller => 'Entry'})

This method is shorthand for creating new instance of L<Router::Simple::SubMapper>.

The arguments will be passed to C<< Router::Simple::SubMapper->new(%args) >>.

=item C<< $match = $router->match($env|$path) >>

Matches a URL against one of the contained routes.

The parameter is either a L<PSGI> $env or a plain string that
represents a path.

This method returns a plain hashref that would look like:

    {
        controller => 'Blog',
        action     => 'daily',
        year => 2010, month => '03', day => '04',
    }

It returns undef if no valid match is found.

=item C<< my ($match, $route) = $router->routematch($env|$path); >>

Match a URL against one of the routes contained.

Will return undef if no valid match is found, otherwise a
result hashref and a L<Router::Simple::Route> object is returned.

=item C<< $router->as_string() >>

Dumps $router as string.

Example output:

    home         GET  /
    blog_monthly GET  /blog/{year}/{month}
                 GET  /blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}
                 POST /comment
                 GET  /

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 THANKS TO

Tatsuhiko Miyagawa

Shawn M Moore

L<routes.py|http://routes.groovie.org/>.

=head1 SEE ALSO

Router::Simple is inspired by L<routes.py|http://routes.groovie.org/>.

L<Path::Dispatcher> is similar, but so complex.

L<Path::Router> is heavy. It depends on L<Moose>.

L<HTTP::Router> has many dependencies. It is not well documented.

L<HTTPx::Dispatcher> is my old one. It does not provide an OO-ish interface.

=head1 THANKS TO

DeNA

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
