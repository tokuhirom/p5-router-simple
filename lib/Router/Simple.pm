package Router::Simple;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.03';
use Router::Simple::SubMapper;
use List::Util qw/max/;
use Carp ();

sub new {
    bless {patterns => []}, shift;
}

sub connect {
    my $self = shift;
    # connect([$name, ]$pattern[, \%dest[, \%opt]])
    if (@_ == 1 || ref $_[1]) {
        unshift(@_, undef);
    }

    my ($name, $pattern, $dest, $opt) = @_;
    Carp::croak("missing pattern") unless $pattern;
    my $row = +{
        name     => $name,
        dest     => $dest,
        on_match => $opt->{on_match},
    };
    if (my $method = $opt->{method}) {
        my $t = ref $method;
        if ($t && $t eq 'ARRAY') {
            $method = join '|', @{$method};
        }
        $row->{method_re} = qr{^(?:$method)$};
    }
    if (my $host = $opt->{host}) {
        $row->{host} = ref $host ? $host : qr(^\Q$host\E$);
    }
    my @capture;
    $row->{pattern} = $pattern;
    $row->{regexp} = do {
        if (ref $pattern) {
            $row->{regexp_capture} = 1;
            $pattern;
        } else {
            $pattern =~ s!
                \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
                :([A-Za-z0-9_]+)              | # /blog/:year
                (\*)                          | # /blog/*/*
                ([^{:*]+)                       # normal string
            !
                if ($1) {
                    my ($name, $pattern) = split /:/, $1;
                    push @capture, $name;
                    $pattern ? "($pattern)" : "([^/]+)";
                } elsif ($2) {
                    push @capture, $2;
                    "([^/]+)";
                } elsif ($3) {
                    push @capture, '__splat__';
                    "(.+)";
                } else {
                    quotemeta($4);
                }
            !gex;
            qr{^$pattern$};
        }
    };
    $row->{capture} = \@capture;
    push @{ $self->{patterns} }, $row;
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

sub match {
    my ($self, $req) = @_;

    my ($path, $host, $method);
    my $req_t = ref $req;
    if ( $req_t eq 'HASH' ) {
        $path   = $req->{PATH_INFO};
        $host   = $req->{HTTP_HOST};
        $method = $req->{REQUEST_METHOD};
    } else {
        $path = $req; # allow plain string
    }

    for my $row (@{$self->{patterns}}) {
        if ($row->{host}) {
            unless ($host =~ $row->{host}) {
                next;
            }
        }
        if ($method && $row->{method_re}) {
            unless ($method =~ $row->{method_re}) {
                next;
            }
        }
        if (my @captured = ($path =~ $row->{regexp})) {
            my %args;
            my @splat;
            if ($row->{regexp_capture}) {
                push @splat, @captured;
            } else {
                for my $i (0..@{$row->{capture}}-1) {
                    if ($row->{capture}->[$i] eq '__splat__') {
                        push @splat, $captured[$i];
                    } else {
                        $args{$row->{capture}->[$i]} = $captured[$i];
                    }
                }
            }
            my $match = +{
                %{$row->{dest}},
                %args,
                ( @splat ? ( splat => \@splat ) : () ),
            };
            if ($row->{on_match}) {
                my $ret = $row->{on_match}->($req, $match);
                next unless $ret;
            }
            return $match;
        }
    }
    return undef; # not matched.
}

sub url_for {
    my ($self, $name, $opts) = @_;

    LOOP:
    for my $row (@{$self->{patterns}}) {
        if ($row->{name} && $row->{name} eq $name) {
            my %required = map { $_ => 1 } @{$row->{capture}};
            my $path = $row->{pattern};
            while (my ($k, $v) = each %$opts) {
                delete $required{$k};
                $path =~ s!\{$k(?:\:.+?)?\}|:$k!$v!g or next LOOP;
            }
            if (not %required) {
                return $path;
            }
        }
    }
    return undef;
}

sub as_string {
    my $self = shift;

    my $mn = max(map { $_->{name} ? length($_->{name}) : 0 } @{$self->{patterns}});
    my $nn = max(map { $_->{method} ? length(join(",",@{$_->{method}})) : 0 } @{$self->{patterns}});

    return join('', map {
        sprintf "%-${mn}s %-${nn}s %s\n", $_->{name}||'', join(',', @{$_->{method} || []}) || '', $_->{pattern}
    } @{$self->{patterns}}) . "\n";
}

1;
__END__

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

':name' notation matches qr{([^/]+)}.

=head2 '*' notation

    $router->connect( '/download/*.*', { controller => 'Download', action => 'file' } );
    ...
    $router->match('/download/path/to/file.xml');
    # => {controller => 'Download', action => 'file', splat => ['path/to/file', 'xml'] }

'*' notation matches qr{(.+)}. You will get the captured argument as
an array ref for the special key C<splat>.

=head2 '{year}' notation

    $router->connect( '/blog/{year}', { controller => 'Blog', action => 'yearly' } );
    ...
    $router->match('/blog/2010');
    # => {controller => 'Blog', action => 'yearly', year => 2010 }

'{year}' notation matches qr{([^/]+)}, and it will be captured.

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

=item $router->connect([$name, ] $pattern, \%destination[, \%options])

Adds a new rule to $router.

    $router->connect( '/', { controller => 'Root', action => 'index' } );
    $router->connect( 'show_entry', '/blog/:id',
        { controller => 'Blog', action => 'show' } );
    $router->connect( '/blog/:id', { controller => 'Blog', action => 'show' } );
    $router->connect( '/comment', { controller => 'Comment', action => 'new_comment' }, {method => 'POST'} );

C<\%destination> will be used by I<match> method.

You can specify some optional things to C<\%options>. The current
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
successful or false otherwise. The first arg is C<$env> which is
either a PSGI environment or a request path, depending on what you
pass to C<match> method; the second is the routing variables that
would be returned if the match succeeds.

The function can modify C<$env> (in case it's a reference) and
C<$match> in place to affect which variables are returned. This allows
a wide range of transformations.

=back

=item $router->submapper($path, [\%dest, [\%opt]])

    $router->submapper('/entry/', {controller => 'Entry'})

This method is shorthand for creating new instance of L<Router::Simple::Submapper>.

The arguments will be passed to C<< Router::Simple::SubMapper->new(%args) >>.

=item $match = $router->match($env|$path)

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

=item $router->url_for($anchor, \%opts)

Generates a path string from the rule named C<$anchor>.

You must pass each parameter in C<\%opts>.

    my $router = Router::Simple->new();
    $router->connect('articles', '/article', {controller => 'Article', action => 'index'});
    $router->connect('edit_articles', '/article/{id}', {controller => 'Article', action => 'edit'});
    $router->url_for('articles'); # => /articles
    $router->url_for('edit_articles', {id => 3}); # => /articles/3/edit

=item $router->as_string()

Dumps $router as string.

Example output:

    home         GET  /
    blog_monthly GET  /blog/{year}/{month}
                 GET  /blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}
                 POST /comment
                 GET  /

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 THANKS TO

Tatsuhiko Miyagawa

Shawn M Moore

L<routes.py|http://routes.groovie.org/>.

=head1 SEE ALSO

Router::Simple is inspired by L<routes.py|http://routes.groovie.org/>.

L<Path::Dispatcher> is similar, but so complex.

L<Path::Router> is heavy. It depends on L<Moose>.

L<HTTP::Router> has many deps. It is not well documented.

L<HTTPx::Dispatcher> is my old one. It does not provide an OOish interface.

=head1 THANKS TO

DeNA

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
