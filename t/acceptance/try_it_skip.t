use strict;
use warnings;

use Test::Sync qw/context/;

sub plan {
    my $ctx = context();
    $ctx->plan(@_);
    $ctx->release;
}

plan(0, skip_all => 'testing skip all');

die "Should not see this";

1;
