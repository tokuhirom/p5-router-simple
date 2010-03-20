use strict;
use warnings;
use Router::Simple;
use Test::More;

my $r = Router::Simple->new()
            ->connect('/say/*/to/*' => {controller => 'Say', action => 'to'})
            ->connect('/download/*.*' => {controller => 'Download', action => 'file'});

is_deeply(
    $r->match('/say/foo/to/bar'),
    {
        controller => 'Say',
        action     => 'to',
        splat      => [qw/foo bar/],
    }
);
is_deeply(
    $r->match('/download/path/to/file.xml'),
    {
        controller => 'Download',
        action     => 'file',
        splat      => ['path/to/file', 'xml'],
    }
);

done_testing;
