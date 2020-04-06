#!perl6

use v6;

use Test;
use ArrayHash;

# TODO Some of these tests are redundant as the way *%_ and such is handled has
# changed since this was first written.

my ($b, %hash, @array);

my %inits =
    '01-init-array-hash' => {
        %hash  := array-hash('a' => 1, 'b' => 2, 'c' => 3);
        @array := %hash;
    },
    '02-init-array-hash-list-pairs' => {
        %hash := array-hash(
            (a => 1, b => 2, c => 3)
        );
        @array := %hash;
    },
    '03-init-array-hash-items' => {
        %hash  := array-hash('a', 1, 'b', 2, 'c', 3);
        @array := %hash;
    },
    '04-init-array-hash-mixed' => {
        %hash  := array-hash('a', 1, 'b' => 2, 'c', 3);
        @array := %hash;
    },
    '05-init-ArrayHash-new' => {
        %hash  := array-hash('a' => 1, 'b' => 2, 'c' => 3);
        @array := %hash;
    },
    '06-init-ArrayHash-new-list-pairs' => {
        %hash := array-hash(
            (a => 1, b => 2, c => 3)
        );
        @array := %hash;
    },
    '07-init-ArrayHash-new-items' => {
        %hash  := array-hash('a', 1, 'b', 2, 'c', 3);
        @array := %hash;
    },
    '08-init-ArrayHash-new-mixed' => {
        %hash  := array-hash('a', 1, 'b' => 2, 'c', 3);
        @array := %hash;
    },
;

my %tests =
    '01-basic' => {
        is %hash<a>, 1, 'hash a';
        is %hash<b>, 2, 'hash b';
        is %hash<c>, 3, 'hash c';

        is @array[0].key, 'a', 'array 0 key';
        is @array[0].value, 1, 'array 0 value';
        is @array[1].key, 'b', 'array 1 key';
        is @array[1].value, 2, 'array 1 value';
        is @array[2].key, 'c', 'array 2 key';
        is @array[2].value, 3, 'array 2 value';
    },
    '02-replace-hash' => {
        %hash<a> = 4;
        is %hash<a>, 4, 'hash a replaced';
        is @array[0].value, 4, 'array 0 value replaced';
    },
    '03-append-hash' => {
        %hash<d> = 5;
        is %hash<d>, 5, 'hash d added';
        is @array[3].key, 'd', 'array d key added';
        is @array[3].value, 5, 'array d value added';
    },
    '04-replace-array' => {
        @array[1] = 'e' => 6;
        is %hash<b>, Any, 'hash b removed';
        is %hash<e>, 6, 'hash e added';
    },
    '06-delete-hash-keeps-blanks' => {
        %hash<b> :delete;
        ok @array[1] ~~ Pair:U, 'after hash delete array 1 is deleted';
        is @array.elems, 3, 'after hash delete elems == 2';
    },
    '07-delete-array-keeps-blanks' => {
        @array[1] :delete;
        ok %hash<b>:!exists, 'after array delete hash b is deleted';
        is %hash.elems, 3, 'after array delete elems still == 3';
    },
    '08-raku' => {
        todo 'It would be best if this passed.', 2;
        my @els = q[:a(1)], q[:b(2)], q[:c(3)];
        is @array.raku, q[array-hash(] ~ @els[0, 1, 2].join(', ') ~ q[)], "array.raku";
        is %hash.perl, q[array-hash(] ~ @els[0, 1, 2].join(', ') ~ q[)], "hash.raku";
    },
    '09-replace-earlier' => {
        @array[3] = 'b' => 8;
        is %hash<b>, 8, 'hash b changed';
        ok @array[1] ~~ Pair:U, 'array 1 nullified';
    },
    '10-replace-later' => {
        @array[0] = 'b' => 9;
        is %hash<b>, 2, 'hash b is same';;
        ok @array[0] ~~ Pair:U, 'array 0 is nullified';
        is @array[1].key, 'b', 'array 1 key is same';
        is @array[1].value, 2, 'array 1 value is same';
    },
    '11-bind-replace-earlier' => {
        @array[3] := :$b;
        is %hash<b>, 42, 'hash b changed';
        ok @array[1] ~~ Pair:U, 'array 1 nullified';
        is @array[3].key, 'b', 'array 3 key is b';
        is @array[3].value, 42, 'array 3 value is 42';
        $b = 24;
        is %hash<b>, 24, 'hash b changed';
        ok @array[1] ~~ Pair:U, 'array 1 nullified';
        is @array[3].key, 'b', 'array 3 key is b';
        is @array[3].value, 24, 'array 3 value is 24';
    },
    '12-bind-replace-later' => {
        @array[0] := :$b;
        is %hash<b>, 2, 'hash b is unchanged';
        ok @array[0] ~~ Pair:U, 'array 0 key nullified';
        is @array[1].key, 'b', 'array 1 key is same';
        is @array[1].value, 2, 'array 1 value is same';
        $b = 24;
        is %hash<b>, 2, 'hash b is unchanged';
        ok @array[0] ~~ Pair:U, 'array 0 key same';
        is @array[1].key, 'b', 'array 1 key is same';
        is @array[1].value, 2, 'array 1 value is same';
    },
    '13-bind-key' => {
        %hash<a> := $b;
        is %hash<a>, $b, 'hash a matches $b';
        is @array[0].value, $b, 'array 0 value matches $b';
        $b = 10;
        is %hash<a>, $b, 'hash a still matches $b';
        is @array[0].value, $b, 'array 0 value still matches $b';
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
        ok @array[3] :!exists, 'nope 3 does not exist';
    },
    '16-delete-key' => {
        my $v = %hash<b> :delete;
        is $v, 2, 'deleted value is correct';
        ok %hash<b>:!exists, 'deleted hash value is gone';
        ok @array[1] ~~ Pair:U, 'deleted pair is gone';
        is %hash.elems, 3, 'deleted hash is the same size';
        is @array.elems, 3, 'delete array is the same size';
    },
    '17-delete-pos' => {
        my $p = @array[1] :delete;
        is $p.key, 'b', 'deleted key is b';
        is $p.value, 2, 'deleted value is 2';
        is %hash.elems, 3, 'deleted hash did not shrink';
        is @array.elems, 3, 'deleted array did not shrink';
        ok @array[1] ~~ Pair:U, 'deleted array position is undef';
    },
    '18-push' => {
        @array.push: 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;
        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        ok @array[1] ~~ Pair:U, 'array 1 nullified';
        ok @array[2] ~~ Pair:U, 'array 2 nullified';
        is @array[3].key, 'd', 'array 3 key is d';
        is @array[3].value, 11, 'array 3 value is 11';
        is @array[4].key, 'e', 'array 4 key is e';
        is @array[4].value, 12, 'array 4 value is 12';
        is @array[5].key, 'b', 'array 5 key is b';
        is @array[5].value, 13, 'array 5 value is 13';
        is @array[6].key, 'c', 'array 6 key is c';
        is @array[6].value, 14, 'array 6 value is 14';
    },
    '19-unshift' => {
        @array.unshift: 'd', 11, 'e' => 12, 'b', 13, 'c' => 14;
        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 2, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'd', 'array 0 key is d';
        is @array[0].value, 11, 'array 0 value is 11';
        is @array[1].key, 'e', 'array 1 key is e';
        is @array[1].value, 12, 'array 1 value is 12';
        ok @array[2] ~~ Pair:U, 'array 2 is nullified';
        ok @array[3] ~~ Pair:U, 'array 3 is nullified';
        is @array[4].key, 'a', 'array 4 key same';
        is @array[4].value, 1, 'array 4 value same';
        is @array[5].key, 'b', 'array 5 key same';
        is @array[5].value, 2, 'array 5 value same';
        is @array[6].key, 'c', 'array 6 key same';
        is @array[6].value, 3, 'array 6 value same';
    },
    '20-splice-push' => {
        @array.splice: 3, 0, 'd' => 11, 'e', 12, 'b', 13, 'c' => 14;
        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        ok @array[1] ~~ Pair:U, 'array 1 nullified';
        ok @array[2] ~~ Pair:U, 'array 2 nullified';
        is @array[3].key, 'd', 'array 3 key is d';
        is @array[3].value, 11, 'array 3 value is 11';
        is @array[4].key, 'e', 'array 4 key is e';
        is @array[4].value, 12, 'array 4 value is 12';
        is @array[5].key, 'b', 'array 5 key is b';
        is @array[5].value, 13, 'array 5 value is 13';
        is @array[6].key, 'c', 'array 6 key is c';
        is @array[6].value, 14, 'array 6 value is 14';
    },
    '21-splice-unshift' => {
        @array.splice: 0, 0, 'd', 11, 'e', 12, 'b' => 13, 'c' => 14;

        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 2, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'd', 'array 0 key is d';
        is @array[0].value, 11, 'array 0 value is 11';
        is @array[1].key, 'e', 'array 1 key is e';
        is @array[1].value, 12, 'array 1 value is 12';
        ok @array[2] ~~ Pair:U, 'array 2 is nullified';
        ok @array[3] ~~ Pair:U, 'array 3 is nullified';
        is @array[4].key, 'a', 'array 4 key same';
        is @array[4].value, 1, 'array 4 value same';
        is @array[5].key, 'b', 'array 5 key same';
        is @array[5].value, 2, 'array 5 value same';
        is @array[6].key, 'c', 'array 6 key same';
        is @array[6].value, 3, 'array 6 value same';
    },
    '22-splice-insert' => {
        @array.splice: 2, 0, 'd' => 11, 'e' => 12, 'b' => 13, 'c' => 14;

        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        ok @array[1] ~~ Pair:U, 'array 1 key same';
        is @array[2].key, 'd', 'array 0 key is d';
        is @array[2].value, 11, 'array 0 value is 11';
        is @array[3].key, 'e', 'array 1 key is e';
        is @array[3].value, 12, 'array 1 value is 12';
        is @array[4].key, 'b', 'array 4 key is b';
        is @array[4].value, 13, 'array 4 value is 13';
        ok @array[5] ~~ Pair:U, 'array 5 is nullified';
        is @array[6].key, 'c', 'array 6 key same';
        is @array[6].value, 3, 'array 6 value same';
    },
    '23-splice-replace' => {
        @array.splice: 1, 1, 'd' => 11, 'e', 12, 'b' => 13, 'c', 14;

        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[1].key, 'd', 'array 0 key is d';
        is @array[1].value, 11, 'array 0 value is 11';
        is @array[2].key, 'e', 'array 1 key is e';
        is @array[2].value, 12, 'array 1 value is 12';
        is @array[3].key, 'b', 'array 4 key is b';
        is @array[3].value, 13, 'array 4 value is 13';
        ok @array[4] ~~ Pair:U, 'array 5 is nullified';
        is @array[5].key, 'c', 'array 6 key same';
        is @array[5].value, 3, 'array 6 value same';
    },
    '24-splice-delete' => {
        @array.splice: 1, 1;

        is %hash<a>, 1, 'hash a same';
        ok %hash<b>:!exists, 'hash b deleted';
        is %hash<c>, 3, 'hash c same';

        is @array[0].key, 'a', 'array 0 key same';
        is @array[0].value, 1, 'array 0 value same';
        is @array[1].key, 'c', 'array 1 key moved up';
        is @array[1].value, 3, 'array 1 value moved up';
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
            init();
            subtest { test() }, $init-desc;
        }
    }, $desc;
}


done-testing;
