package Router::Simple::SubMapper;
use strict;
use warnings;
use Scalar::Util qw/weaken/;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    weaken($self->{parent});
    $self;
}

sub connect {
    my ($self, $pattern, $res, $opt) = @_;
    $self->{parent}->connect(
        $self->{path_prefix} . $pattern,
        { controller => $self->{controller}, action => $self->{action}, %$res },
        { method => $self->{method}, %{ $opt || {} } }
    );
}

1;
