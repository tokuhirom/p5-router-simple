use inc::Module::Install;
name 'Router-Simple';
all_from 'lib/Router/Simple.pm';

# requires '';


readme_markdown_from 'lib/Router/Simple.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests('xt');
# use_test_base;
auto_include;
WriteAll;
