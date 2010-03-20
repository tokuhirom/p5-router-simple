use strict;
use warnings;
use Test::More;
plan skip_all => 'Test::Synopsis is required for testing' unless eval "use Test::Synopsis; 1";
all_synopsis_ok();
