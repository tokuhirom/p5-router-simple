package Router::Simple;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.01';

sub new {
    bless {}, shift;
}

sub connect {
    my ($self, $pattern, $res, $opt) = @_;
    my $row = +{
        controller => $res->{controller},
        action     => $res->{action},
    };
    if (my $method = $opt->{method}) {
        my $t = ref $method;
        if ($t && $t eq 'ARRAY') {
            $method = join '|', @{$method};
        }
        $row->{method} = qr{^(?:$method)$};
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
            $pattern =~ s!\{((?:\{[0-9,]+\}|[^{}]+)+)\}|:([A-Za-z0-9_]+)|([^{:]+)!
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
            !ge;
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

sub match {
    my ($self, $req) = @_;

    my $path = $req->uri->path;
    my $host = $req->uri->host;
    my $method = $req->method;
    for my $row (@{$self->{patterns}}) {
        if ($row->{host}) {
            unless ($host =~ $row->{host}) {
                next;
            }
        }
        if ($row->{method}) {
            unless ($method =~ $row->{method}) {
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
    return; # not matched.
}

1;
__END__

=encoding utf8

=head1 NAME

Router::Simple -

=head1 SYNOPSIS

    use Router::Simple;

    my $router = Router::Simple->new();
    $router->get('/', {controller => 'Root', action => 'show'});
    $router->post('/blog/{year}/{month}', {controller => 'Blog', action => 'monthly'});

=head1 DESCRIPTION

Router::Simple is

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
