use inc::Module::Install;
name 'Router-Simple';
all_from 'lib/Router/Simple.pm';

requires 'parent';
requires 'List::Util'; # was first released with perl 5.007003
requires 'Class::Accessor::Fast';
requires 'Test::More' => 0.88; # done_testing

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
author_tests('xt');
WriteAll;
