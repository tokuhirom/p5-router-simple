use inc::Module::Install;
name 'Router-Simple';
all_from 'lib/Router/Simple.pm';

requires 'parent';
requires 'List::Util'; # was first released with perl 5.007003
requires 'Class::Accessor::Fast';

readme_markdown_from('lib/Router/Simple.pm');
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests('xt');
auto_include;
WriteAll;
