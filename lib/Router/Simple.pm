package Router::Simple;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.01';
use Router::Simple::SubMapper;
use List::Util qw/max/;
use Carp ();

sub new {
    bless {}, shift;
}

sub connect {
    my $self = shift;
    # connect([$name, ]$pattern[, \%dest[, \%opt]])
    if (@_ == 1 || ref $_[1]) {
        unshift(@_, undef);
    }

    my ($name, $pattern, $res, $opt) = @_;
    Carp::croak("missing pattern") unless $pattern;
    my $row = +{
        name       => $name,
        controller => $res->{controller},
        action     => $res->{action},
    };
    if (my $method = $opt->{method}) {
        my $t = ref $method;
        $row->{method} = $t ? $method : [$method];
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
            $pattern;
        } else {
            $pattern =~ s!
                \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
                :([A-Za-z0-9_]+)              | # /blog/:year
                ([^{:]+)                        # normal string
            !
                if ($1) {
                    my ($name, $pattern) = split /:/, $1;
                    push @capture, $name;
                    $pattern ? "($pattern)" : "([^/]+)";
                } elsif ($2) {
                    push @capture, $2;
                    "([^/]+)";
                } else {
                    quotemeta($3)
                }
            !gex;
            qr{^$pattern$};
        }
    };
    $row->{capture} = \@capture;
    push @{ $self->{patterns} }, $row;
}

sub _zip {
    my ($x, $y) = @_;
    map { $x->[$_], $y->[$_] } (0..@$x-1);
}

sub submapper {
    my ($self, %args) = @_;
    my $submapper = Router::Simple::SubMapper->new(parent => $self, %args);
    return $submapper;
}

sub match {
    my ($self, $req) = @_;

    my ($path, $host, $method);
    if ( not ref $req ) {
        $path = $req;
    }
    else {
        $path   = $req->uri->path;
        $host   = $req->uri->host;
        $method = $req->method;
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
            my %args = _zip($row->{capture}, \@captured);
            return +{
                controller => $row->{controller} || delete $args{controller},
                action     => $row->{action}     || delete $args{action},
                args       => \%args,
            };
        }
    }
    return undef; # not matched.
}

sub resource {
    my ($self, $controller, $resource_name, $opt) = @_;

    my $collection_name = (
        delete $opt->{collection_name} || do {
            require Lingua::EN::Inflect;
            Lingua::EN::Inflect::PL($resource_name);
        }
    );

    $self->connect(
        $collection_name,
        "/$collection_name",
        {
            controller => $controller,
            action     => "create",
        },
        { method => ["POST"] }
    );
    $self->connect(
        $collection_name,
        "/$collection_name",
        {
            controller => $controller,
            action     => "index",
        },
        { method => ["GET"] }
    );
    $self->connect(
        "formatted_$collection_name",
        "/$collection_name.{format}",
        {
            controller => $controller,
            action     => "index",
        },
        { method => ["GET"] }
    );
    $self->connect(
        "new_$collection_name",
        "/$collection_name/new",
        {
            controller => $controller,
            action     => "new",
        },
        { method => ["GET"] }
    );
    $self->connect(
        "formatted_new_$collection_name",
        "/$collection_name/new.{format}",
        {
            controller => $controller,
            action     => "new",
        },
        { method => ["GET"] }
    );
    $self->connect(
        "/$collection_name/{id}",
        {
            controller => $controller,
            action     => "update",
        },
        { method => ["PUT"] }
    );
    $self->connect(
        "/$collection_name/{id}",
        {
            controller => $controller,
            action     => "delete",
        },
        { method => ["DELETE"] }
    );
    $self->connect(
        "formatted_edit_$collection_name",
        "/$collection_name/{id}.{format}/edit",
        {
            controller => $controller,
            action     => "edit",
        },
        { method => ["GET"] }
    );
    $self->connect(
        "edit_$collection_name",
        "/$collection_name/{id}/edit",
        {
            controller => $controller,
            action     => "edit",
        },
        { method => ["GET"] }
    );
    $self->connect(
        "formatted_$resource_name",
        "/$collection_name/{id}.{format}",
        {
            controller => $controller,
            action     => "show",
        },
        { method => ["GET"] }
    );
    $self->connect(
        "$resource_name",
        "/$collection_name/{id}",
        {
            controller => $controller,
            action     => "show",
        },
        { method => ["GET"] }
    );
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
        sprintf "%-${mn}s %-${nn}s %s\n", $_->{name}||'', join(',', @{$_->{method}}) || '', $_->{pattern}
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

=head1 DESCRIPTION

Router::Simple is simple router class.

=head1 METHODS

=over 4

=item my $router = Router::Simple->new();

create new instance of Router::Simple.

=item $router->connect([$name, ] $pattern, \%destination[, \%options])

Add new rule for $router.

    $router->connect( '/', { controller => 'Root', action => 'index' } );
    $router->connect( 'show_entry', '/blog/:id',
        { controller => 'Blog', action => 'show' } );
    $router->connect( '/blog/:id', { controller => 'Blog', action => 'show' } );
    $router->connect( '/comment', { controller => 'Comment', action => 'new_comment' }, {method => 'POST'} );

define the new route to $router.

=item $router->match($req|$path)

Match a URL against against one of the routes contained.

$req is a L<HTTP::Request> like object or plain hashref.
If $req is object, it must respond to B<uri> and B<method>.
Off course, you can use L<Plack::Request> as $req.

If you want to use Router::Simple for not HTTP routing such as FTP, you can pass $req as plain string.

This method returns a plain hashref.Example return value as following:

    {
        controller => 'Blog',
        action     => 'daily',
        args       => { year => 2010, month => '03', day => '04' },
    }

Will return None if no valid match is found.

=item $router->resource($controller, $resource_name, \%opt)

Router::Simple makes it easy to configure RESTful web services.
B<resource> creates a set of add/modify/delete routes conforming to the Atom publishing protocol.

This method makes the map as following:

    $router->resource('Article', 'article', {collection_name => 'articles'})

    articles                POST   /articles
    articles                GET    /articles
    formatted_articles      GET    /articles.{format}
    new_articles            GET    /articles/new
    formatted_new_articles  GET    /articles/new.{format}
                            PUT    /articles/{id}
                            DELETE /articles/{id}
    formatted_edit_articles GET    /articles/{id}.{format}/edit
    edit_articles           GET    /articles/{id}/edit
    formatted_article       GET    /articles/{id}.{format}
    article                 GET    /articles/{id}

=item $router->url_for($anchor, \%opts)

generate path string from rule named $anchor.

You must pass the each parameters to \%opts.

    my $router = Router::Simple->new();
    $router->resource('Article', 'article');
    $router->url_for('articles'); # => /articles
    $router->url_for('edit_articles', {id => 3}); # => /articles/3/edit

=item $router->as_string()

Dump $router as string.

The example output is following:

    home         GET  /
    blog_monthly GET  /blog/{year}/{month}
                 GET  /blog/{year:\d{1,4}}/{month:\d{2}}/{day:\d\d}
                 POST /comment
                 GET  /

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

Router::Simple is inspired by L<routes.py|http://routes.groovie.org/>.

L<Path::Dispatcher> is similar, but so complex.

L<Path::Router> is heavy.It depend to L<Moose>.

L<HTTP::Router> is heavy, too.It depend to Mouse, and more.

L<HTTPx::Dispatcher> is my old one.It does not provides OOish interface.

=head1 THANKS TO

DeNA

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
