#!perl6

use v6;

use Test;
use ArrayHash;

# TODO Some of these tests are redundant as the way *%_ and such is handled has
# changed since this was first written.

my ($b, %hash, @array);

my %inits =
    '01-init-multi-hash' => {
        %hash  := multi-hash('a' => 1, 'b' => 2, 'c' => 3, 'a' => 4);
        @array := %hash;
    },
    '02-init-multi-hash-list-pairs' => {
        %hash  := multi-hash(
            (a => 1, b => 2, c => 3, a => 4)
        );
        @array := %hash;
    },
    '03-init-multi-hash-items' => {
        %hash  := multi-hash('a', 1, 'b', 2, 'c', 3, 'a', 4);
        @array := %hash;
    },
    '04-init-multi-hash-mixed' => {
        %hash  := multi-hash('a', 1, 'b' => 2, 'c', 3, 'a' => 4);
        @array := %hash;
    },
    '05-init-ArrayHash-new' => {
        %hash  := ArrayHash.new('a' => 1, 'b' => 2, 'c' => 3, 'a' => 4, :multivalued);
        @array := %hash;
    },
    '06-init-ArrayHash-new-list-pairs' => {
        %hash  := ArrayHash.new(
            (a => 1, b => 2, c => 3, a => 4),
            :multivalued
        );
        @array := %hash;
    },
    '07-init-ArrayHash-new-items' => {
        %hash  := ArrayHash.new('a', 1, 'b', 2, 'c', 3, 'a', 4, :multivalued);
        @array := %hash;
    },
    '08-init-ArrayHash-new-mixed' => {
        %hash  := ArrayHash.new('a', 1, 'b' => 2, 'c', 3, 'a' => 4, :multivalued);
        @array := %hash;
    },
;

my %tests =
    '01-basic' => {
        is %hash<a>, 4, 'hash a';
        is %hash<b>, 2, 'hash b';
        is %hash<c>, 3, 'hash c';

        is @array[0].key, 'a', 'array 0 key';
        is @array[0].value, 1, 'array 0 value';
        is @array[1].key, 'b', 'array 1 key';
        is @array[1].value, 2, 'array 1 value';
        is @array[2].key, 'c', 'array 2 key';
        is @array[2].value, 3, 'array 2 value';
        is @array[3].key, 'a', 'array 3 key';
        is @array[3].value, 4, 'array 3 value';
    },
    '02-replace-hash' => {
        %hash<a> = 5;
        is %hash<a>, 5, 'hash a replaced';
        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[3].key, 'a', 'array 3 key same';
        is @array[3].value, 5, 'array 3 value replace';
    },
    '03-append-hash' => {
        %hash<d> = 5;
        is %hash<d>, 5, 'hash d added';
        is @array[4].key, 'd', 'array d key added';
        is @array[4].value, 5, 'array d value added';
    },
    '04-replace-array' => {
        @array[1] = 'e' => 6;
        is %hash<b>, Any, 'hash b removed';
        is %hash<e>, 6, 'hash e added';

        @array[3] = 'f' => 7;
        is %hash<a>, 1, 'hash a changed';
        is %hash<f>, 7, 'hash f added';
    },
    '06-delete-hash-does-not-squashes-blanks' => {
        %hash<b> :delete;
        ok @array[1] ~~ Pair:U, 'after hash b delete array value 1 is undefined';
        is @array.elems, 4, 'after hash delete elems still == 4';

        %hash<a> :delete;
        ok @array[0] ~~ Pair:U, 'after hash a delete array value 0 is undefined';
        is @array.elems, 3, 'after hash delete elems == 3 because last item is gone';
    },
    '07-delete-array-keeps-blanks' => {
        @array[1] :delete;
        is %hash.elems, 4, 'after array delete elems still == 4';
    },
    '08-raku' => {
        todo 'It would be best if this passed.', 2;
        if @array^.can('raku') {
            my @els = q[:a(1)], q[:b(2)], q[:c(3)], q[:a(4)];
            is @array.raku, q[multi-hash(] ~ @els[0..3].join(', ') ~ q[)], "array.raku";
            is %hash.raku, q[multi-hash(] ~ @els[0..3].join(', ') ~ q[)], "hash.raku";
        }
        else {
            skip 'The .raku method does not exist in this version of Perl 6.', 2;
        }
    },
    '09-replace-earlier' => {
        @array[3] = 'b' => 8;
        is %hash<b>, 8, 'hash b changed';
        is @array[1].key, 'b', 'array 1 key same';
        is @array[1].value, 2, 'array 1 value same';
        is @array[3].key, 'b', 'array 3 key added';
        is @array[3].value, 8, 'array 3 value added';
    },
    '10-replace-later' => {
        @array[0] = 'b' => 9;
        is %hash<b>, 2, 'hash b is unchanged';
        is @array[0].key, 'b', 'array 0 key set';
        is @array[0].value, 9, 'array 0 value set';
        is @array[1].key, 'b', 'array 1 key same';
        is @array[1].value, 2, 'array 1 key same';
    },
    '11-bind-replace-earlier' => {
        @array[3] := 'b' => 8;
        is %hash<b>, 8, 'hash b changed';
        is @array[1].key, 'b', 'array 1 key same';
        is @array[1].value, 2, 'array 1 value same';
        is @array[3].key, 'b', 'array 3 key added';
        is @array[3].value, 8, 'array 3 value added';
    },
    '12-bind-replace-later' => {
        @array[0] := 'b' => 9;
        is %hash<b>, 2, 'hash b is unchanged';
        is @array[0].key, 'b', 'array 0 key set';
        is @array[0].value, 9, 'array 0 value set';
        is @array[1].key, 'b', 'array 1 key same';
        is @array[1].value, 2, 'array 1 value same';
    },
    '13-bind-key' => {
        %hash<a> := $b;
        is %hash<a>, 42, 'hash a changed';
        $b = 10;
        is %hash<a>, 10, 'hash a changed again';
        is @array[0].value, 1, 'array 0 value same';
        is @array[3].value, $b, 'array 3 value changed';
    },
    '14-exists-key' => {
        ok %hash<a> :exists, 'yep a exists';
        ok %hash<b> :exists, 'yep b exists';
        ok %hash<c> :exists, 'yep c exists';
        ok %hash<d> :!exists, 'nope d does not exist';
    },
    '15-exists-pos' => {
        ok @array[0] :exists, 'yep 0 exists';
        ok @array[1] :exists, 'yep 1 exists';
        ok @array[2] :exists, 'yep 2 exists';
        ok @array[3] :exists, 'yep 3 exists';
        ok @array[4] :!exists, 'nope 4 does not exist';
    },
    '16-delete-key' => {
        my $v = %hash<b> :delete;
        is $v, 2, 'deleted value is correct';
        is %hash.elems, 4, 'deleted hash did not shrink';
        is @array.elems, 4, 'delete array did not shrink';
    },
    '17-delete-pos' => {
        my $p = @array[1] :delete;
        is $p.key, 'b', 'deleted key is b';
        is $p.value, 2, 'deleted value is 2';
        is %hash.elems, 4, 'deleted hash did not shrink';
        is @array.elems, 4, 'deleted array did not shrink';
        is @array[1], Pair, 'deleted array position is undef';
    },
    '18-push' => {
        @array.push: 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[1].key, 'b', 'array 1 key same';
        is @array[1].value, 2, 'array 1 value same';
        is @array[2].key, 'c', 'array 2 key same';
        is @array[2].value, 3, 'array 2 value same';
        is @array[3].key, 'a', 'array 3 key same';
        is @array[3].value, 4, 'array 3 value changed';
        is @array[4].key, 'd', 'array 4 key added d';
        is @array[4].value, 11, 'array 4 value added 11';
        is @array[5].key, 'e', 'array 5 key added e';
        is @array[5].value, 12, 'array 5 value added 12';
        is @array[6].key, 'b', 'array 6 key added b';
        is @array[6].value, 13, 'array 6 value added 13';
        is @array[7].key, 'c', 'arrary 7 key added c';
        is @array[7].value, 14, 'array 7 key added 14';
    },
    '19-unshift' => {
        @array.unshift: 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 2, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'd', 'array 0 key same';
        is @array[0].value, 11, 'array 0 value same';
        is @array[1].key, 'e', 'array 1 key same';
        is @array[1].value, 12, 'array 1 value same';
        is @array[2].key, 'b', 'array 2 key same';
        is @array[2].value, 13, 'array 2 value same';
        is @array[3].key, 'c', 'array 3 key same';
        is @array[3].value, 14, 'array 3 value same';
        is @array[4].key, 'a', 'array 0 key same';
        is @array[4].value, 1, 'array 0 value same';
        is @array[5].key, 'b', 'array 1 key same';
        is @array[5].value, 2, 'array 1 value same';
        is @array[6].key, 'c', 'array 2 key same';
        is @array[6].value, 3, 'array 2 value same';
        is @array[7].key, 'a', 'array 3 key same';
        is @array[7].value, 4, 'array 3 value same';
    },
    '20-splice-push' => {
        @array.splice: 4, 0, 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[1].key, 'b', 'array 1 key same';
        is @array[1].value, 2, 'array 1 value same';
        is @array[2].key, 'c', 'array 2 key same';
        is @array[2].value, 3, 'array 2 value same';
        is @array[3].key, 'a', 'array 3 key same';
        is @array[3].value, 4, 'array 3 value same';
        is @array[4].key, 'd', 'array 4 key added d';
        is @array[4].value, 11, 'array 4 value added 11';
        is @array[5].key, 'e', 'array 5 key added e';
        is @array[5].value, 12, 'array 5 value added 12';
        is @array[6].key, 'b', 'array 6 key added b';
        is @array[6].value, 13, 'array 6 value added 13';
        is @array[7].key, 'c', 'arrary 7 key added c';
        is @array[7].value, 14, 'array 7 key added 14';
    },
    '21-splice-unshift' => {
        @array.splice: 0, 0, 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 2, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'd', 'array 0 key same';
        is @array[0].value, 11, 'array 0 value same';
        is @array[1].key, 'e', 'array 1 key same';
        is @array[1].value, 12, 'array 1 value same';
        is @array[2].key, 'b', 'array 2 key same';
        is @array[2].value, 13, 'array 2 value same';
        is @array[3].key, 'c', 'array 3 key same';
        is @array[3].value, 14, 'array 3 value same';
        is @array[4].key, 'a', 'array 0 key same';
        is @array[4].value, 1, 'array 0 value same';
        is @array[5].key, 'b', 'array 1 key same';
        is @array[5].value, 2, 'array 1 value same';
        is @array[6].key, 'c', 'array 2 key same';
        is @array[6].value, 3, 'array 2 value same';
        is @array[7].key, 'a', 'array 3 key same';
        is @array[7].value, 4, 'array 3 value same';
    },
    '22-splice-insert' => {
        @array.splice: 2, 0, 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;
        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 13, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[1].key, 'b', 'array 1 key same';
        is @array[1].value, 2, 'array 1 value same';
        is @array[2].key, 'd', 'array 2 key same';
        is @array[2].value, 11, 'array 2 value same';
        is @array[3].key, 'e', 'array 3 key same';
        is @array[3].value, 12, 'array 3 value same';
        is @array[4].key, 'b', 'array 4 key same';
        is @array[4].value, 13, 'array 4 value same';
        is @array[5].key, 'c', 'array 5 key same';
        is @array[5].value, 14, 'array 5 value same';
        is @array[6].key, 'c', 'array 6 key same';
        is @array[6].value, 3, 'array 6 value same';
        is @array[7].key, 'a', 'array 7 key same';
        is @array[7].value, 4, 'array 7 value same';
    },
    '23-splice-replace' => {
        @array.splice: 1, 1, 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;

        is %hash<a>, 4, 'hash a same';
        is %hash<b>, 13, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[1].key, 'd', 'array 2 key same';
        is @array[1].value, 11, 'array 2 value same';
        is @array[2].key, 'e', 'array 3 key same';
        is @array[2].value, 12, 'array 3 value same';
        is @array[3].key, 'b', 'array 4 key same';
        is @array[3].value, 13, 'array 4 value same';
        is @array[4].key, 'c', 'array 5 key same';
        is @array[4].value, 14, 'array 5 value same';
        is @array[5].key, 'c', 'array 6 key same';
        is @array[5].value, 3, 'array 6 value same';
        is @array[6].key, 'a', 'array 7 key same';
        is @array[6].value, 4, 'array 7 value same';
    },
    '24-splice-delete' => {
        @array.splice: 1, 1;
        is %hash<a>, 4, 'hash a same';
        is %hash<c>, 3, 'hash c same';
        is %hash.elems, 3, 'array has 2 elems';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[1].key, 'c', 'array 1 key same as previous array 2';
        is @array[1].value, 3, 'array 1 value same as previous array 2';
        is @array[2].key, 'a', 'array 2 key same as previous array 3';
        is @array[2].value, 4, 'array 2 value same as previous array 3';
        is @array.elems, 3, 'array has 3 elems';
    },
    '25-clone' => {
        my @clone-array := @array.clone;
        my %clone-hash  := %hash.clone;

        is-deeply @clone-array, @array, 'cloned array matches original';
        is-deeply %clone-hash, %hash, 'cloned hash matches original';
    },
;

my $rand-seed = %*ENV<TEST_RAND_SEED>;
$rand-seed //= sprintf("%04d%02d%02d", .year, .month, .day) with Date.today;
srand($rand-seed.Int);
diag("TEST_RAND_SEED = $rand-seed");

for %tests.sort.pick(*) -> (:key($desc), :value(&test)) {
    subtest {
        for %inits.sort -> (:key($init-desc), :value(&init)) {
            $b = 42;
            diag "init: $init-desc, test: $desc";
            my $o = init();
            subtest { temp $_ = $o; test() }, $init-desc;
        }
    }, $desc;
}


done-testing;
