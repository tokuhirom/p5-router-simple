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
    $pattern = $self->{path_prefix}.$pattern if $self->{path_prefix};
    $res ||= +{};
    $opt ||= +{};
    $self->{parent}->connect(
        $pattern,
        { controller => $self->{controller}, action => $self->{action}, %$res },
        { method => $self->{method}, %$opt }
    );
    $self; # chained method
}

1;
__END__

=head1 NAME

Router::Simple::SubMapper

=head1 DESCRIPTION

Do not use this class directly.

