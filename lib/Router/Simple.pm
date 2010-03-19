package Router::Simple;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.01';
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

    my ($name, $pattern, $res, $opt) = @_;
    Carp::croak("missing pattern") unless $pattern;
    my $row = +{
        name       => $name,
    };
    if (ref $res eq 'CODE') {
        $row->{code} = $res;
    } else {
        $row->{controller} = $res->{controller};
        $row->{action}    = $res->{action};
    }
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
    my ($self, @args) = @_;

    # ->submapper('/entry/, controller => 'Entry')
    unshift @args, 'path_prefix' if @args%2==1;

    my $submapper = Router::Simple::SubMapper->new(parent => $self, @args);
    return $submapper;
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
            if ($row->{code}) {
                return +{
                    code       => $row->{code},
                    args       => \%args,
                    (@splat ? (splat => \@splat) : ()),
                };
            } else {
                return +{
                    controller => $row->{controller} || delete $args{controller},
                    action     => $row->{action}     || delete $args{action},
                    args       => \%args,
                    (@splat ? (splat => \@splat) : ()),
                };
            }
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
            return "MyApp::C::$p->{controller}"->can($p->{action})->($env, $p->{args});
        } else {
            [404, [], ['not found']];
        }
    };

=head1 DESCRIPTION

Router::Simple is simple router class.

The main purpose is dispatcher for web application.

Router::Simple is L<PSGI> friendly.

=head1 HOW TO WRITE ROUTING RULE

=head2 plain string 

    $router->connect( '/foo', { controller => 'Root', action => 'foo' } );

=head2 :name notation

    $router->connect( '/wiki/:page', { controller => 'WikiPage', action => 'show' } );
    ...
    $router->match('/wiki/john');
    # => {controller => 'WikiPage', action => 'show', args => { page => 'john' } }

':name' notation matches qr{([^/]+)}.

=head2 '*' notation

    $router->connect( '/download/*.*', { controller => 'Download', action => 'file' } );
    ...
    $router->match('/download/path/to/file.xml');
    # => {controller => 'Download', action => 'file', splat => ['path/to/file', 'xml'] }

'*' notation matches qr{(.+)}.You will got captured arguments as 'splat'.

=head2 '{year}' notation

    $router->connect( '/blog/{year}', { controller => 'Blog', action => 'yearly' } );
    ...
    $router->match('/blog/2010');
    # => {controller => 'Blog', action => 'yearly', args => { year => 2010 } }


'{year}' notation matches qr{([^/]+)}, and it will capture to 'args'.

=head2 '{year:[0-9]+}' notation

    $router->connect( '/blog/{year:[0-9]+}/{month:[0-9]{2}}', { controller => 'Blog', action => 'monthly' } );
    ...
    $router->match('/blog/2010/04');
    # => {controller => 'Blog', action => 'monthly', args => { year => 2010, month => '04' } }

You can specify the regexp for named capture.

=head2 regexp

    $router->connect( qr{/blog/(\d+)/([0-9]{2})', { controller => 'Blog', action => 'monthly' } );
    ...
    $router->match('/blog/2010/04');
    # => {controller => 'Blog', action => 'monthly', splat => [2010, '04'] }

You can use Perl5's powerful regexp directly.

=head1 METHODS

=over 4

=item my $router = Router::Simple->new();

create new instance of Router::Simple.

=item $router->connect([$name, ] $pattern, $destination[, \%options])

Add new rule for $router.

    $router->connect( '/', { controller => 'Root', action => 'index' } );
    $router->connect( 'show_entry', '/blog/:id',
        { controller => 'Blog', action => 'show' } );
    $router->connect( '/blog/:id', { controller => 'Blog', action => 'show' } );
    $router->connect( '/comment', { controller => 'Comment', action => 'new_comment' }, {method => 'POST'} );

define the new route to $router.

You can specify the $destination as \%hashref or \&coderef.The coderef should have keys named B<controller> and B<action>.

You can specify some optional things to \%options.Current version supports 'method' and 'host'.
'method' is ArrayRef[String] or String, that matches B<REQUEST_METHOD> in $req.
'host' is String or Regexp, that matches B<HTTP_HOST> in $req.

=item $router->submapper([$pathprefix, ] %args)

    $router->submapper('/entry/, controller => 'Entry')
    $router->submapper(path_prefix => '/entry/, controller => 'Entry')

This method is shorthand for creating new instance of L<Router::Simple::Submapper>.

The arguments will pass to Router::Simple::SubMapper->new(%args).

=item $router->match($req|$path)

Match a URL against against one of the routes contained.

$req is a L<PSGI>'s $env or plain string.

This method returns a plain hashref.

If you are using +{ controller => 'Blog', action => 'daily' } style, then you got return value as following:

    {
        controller => 'Blog',
        action     => 'daily',
        args       => { year => 2010, month => '03', day => '04' },
    }

If you are using sub { ... } as action, you will get the following:

    {
        code => sub { 'DUMMY' },
        args => { year => 2010, month => '03', day => '04' },
    }

Will return undef if no valid match is found.

=item $router->url_for($anchor, \%opts)

generate path string from rule named $anchor.

You must pass the each parameters to \%opts.

    my $router = Router::Simple->new();
    $router->connect('articles', '/article', {controller => 'Article', action => 'index'});
    $router->connect('edit_articles', '/article/{id}', {controller => 'Article', action => 'edit'});
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

=head1 THANKS TO

Tatsuhiko Miyagawa

L<routes.py|http://routes.groovie.org/>.

=head1 SEE ALSO

Router::Simple is inspired by L<routes.py|http://routes.groovie.org/>.

L<Path::Dispatcher> is similar, but so complex.

L<Path::Router> is heavy.It depend to L<Moose>.

L<HTTP::Router> has many deps.It doesn't well documented.

L<HTTPx::Dispatcher> is my old one.It does not provides OOish interface.

=head1 THANKS TO

DeNA

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
