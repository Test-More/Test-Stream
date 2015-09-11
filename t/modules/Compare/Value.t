use Test::Stream -V1, Spec, Class => ['Test::Stream::Compare::Value'];

my $undef = $CLASS->new();
my $number = $CLASS->new(input => '22.0');
my $string = $CLASS->new(input => 'hello');
my $untru1 = $CLASS->new(input => '');
my $untru2 = $CLASS->new(input => 0);

isa_ok($_, $CLASS, 'Test::Stream::Compare') for $undef, $number, $string, $untru1, $untru2;

tests name => sub {
    is($undef->name,  '<UNDEF>', "got expected name");
    is($number->name, '22.0',    "got expected name");
    is($string->name, 'hello',   "got expected name");
    is($untru1->name, '',        "got expected name");
    is($untru2->name, '0',       "got expected name");
};

tests operator => sub {
    is($undef->operator(),      '',   "no operator for undef + nothing");
    is($undef->operator(undef), '==', "== for 2 undefs");
    is($undef->operator('x'),   '',   "no operator for undef + string");
    is($undef->operator(1),     '',   "no operator for undef + number");

    is($number->operator(),      '',   "no operator for number + nothing");
    is($number->operator(undef), '',   "no operator for number + undef");
    is($number->operator('x'),   'eq', "eq operator for number + string");
    is($number->operator(1),     '==', "== operator for number + number");

    is($string->operator(),      '',   "no operator for string + nothing");
    is($string->operator(undef), '',   "no operator for string + undef");
    is($string->operator('x'),   'eq', "eq operator for string + string");
    is($string->operator(1),     'eq', "eq operator for string + number");

    is($untru1->operator(),      '',   "no operator for empty string + nothing");
    is($untru1->operator(undef), '',   "no operator for empty string + undef");
    is($untru1->operator('x'),   'eq', "eq operator for empty string + string");
    is($untru1->operator(1),     'eq', "eq operator for empty string + number");

    is($untru2->operator(),      '',   "no operator for 0 + nothing");
    is($untru2->operator(undef), '',   "no operator for 0 + undef");
    is($untru2->operator('x'),   'eq', "eq operator for 0 + string");
    is($untru2->operator(1),     '==', "eq operator for 0 + number");
};

tests verify => sub {
    ok(!$undef->verify({}),   'Ref does not verify against undef');
    ok($undef->verify(undef), 'undef verifies against undef');
    ok(!$undef->verify('x'),  'string will not validate against undef');
    ok(!$undef->verify(1),    'number will not verify against undef');

    ok(!$number->verify({}),    'ref will not verify');
    ok(!$number->verify(undef), 'looking for a number, not undef');
    ok(!$number->verify('x'),   'not looking for a string');
    ok(!$number->verify(1),     'wrong number');
    ok($number->verify(22),     '22.0 == 22');
    ok($number->verify('22.0'), 'exact match with decimal');

    ok(!$string->verify({}),     'ref will not verify');
    ok(!$string->verify(undef),  'looking for a string, not undef');
    ok(!$string->verify('x'),    'looking for a different string');
    ok(!$string->verify(1),      'looking for a string, not a number');
    ok($string->verify('hello'), 'exact match');

    ok(!$untru1->verify({}),    'ref will not verify');
    ok(!$untru1->verify(undef), 'looking for a string, not undef');
    ok(!$untru1->verify('x'),   'wrong string');
    ok(!$untru1->verify(1),     'not a number');
    ok($untru1->verify(''),     'exact match, empty string');

    ok(!$untru2->verify({}),    'ref will not verify');
    ok(!$untru2->verify(undef), 'undef is not 0 for this test');
    ok(!$untru2->verify('x'),   'x is not 0');
    ok(!$untru2->verify(1),     '1 is not 0');
    ok($untru2->verify(0),      'got 0');
    ok($untru2->verify('0.0'),  '0.0 == 0');
    ok($untru2->verify('-0.0'), '-0.0 == 0');
};

done_testing;

__END__

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 if ref $got;

    my $input = $self->{+INPUT};
    return !defined($got) unless defined $input;
    return 0 unless defined($got);

    my $op = $self->operator($got);

    return $input == $got if $op eq '==';
    return $input eq $got;
}

1;
