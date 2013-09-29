requires 'perl', '5.008_001';

requires 'Class::Accessor::Lite', '0.05';
requires 'List::Util';
requires 'parent';
requires 'Scalar::Util';

on test => sub {
    requires 'Test::More', '0.98';
};
