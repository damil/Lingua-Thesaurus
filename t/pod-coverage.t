#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

plan skip_all => "POD coverage: release testing only"
  unless $ENV{RELEASE_TESTING};

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

all_pod_coverage_ok({ also_private => [ qr/^[A-Z_]+$/ ]}, "pod coverage");
