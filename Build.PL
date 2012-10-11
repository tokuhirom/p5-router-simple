use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    author               => 'Tokuhiro Matsuno',
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => { 'Test::More' => '0.98' },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        'perl'                  => '5.00800',
        'Test::More'            => '0.88',
        'List::Util'            => '0',
        'parent'                => '0',
        'Class::Accessor::Fast' => '0'
    },
    no_index    => { 'directory' => [ 'inc', 't', 'xt' ] },
    name        => 'Router-Simple',
    module_name => 'Router::Simple',

    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
