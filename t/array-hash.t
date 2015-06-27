#!perl6

use v6;

use Test;
use ArrayHash;

my ($b, %hash, @array);

sub make-iter(@o) {
    class { 
        method CALL-ME() { @o.shift } 
        method AT-POS($pos) { @o[$pos] } 
    }
}

my %inits = 
    '01-init-hash-then-array' => {
        $b      = 2;
        %hash  := array-hash('a' =x> 1, 'b' =X> $b, 'c' =x> 3);
        @array := %hash;
        make-iter(@ = 0, 1, 2);
    }, 
    '02-init-array-then-hash' => {
        $b      = 2;
        @array := array-hash('a' =x> 1, 'b' =X> $b, 'c' =x> 3);
        %hash  := @array;
        make-iter(@ = 0, 1, 2);
    }, 
    '03-init-from-pairs' => {
        $b = 2;
        my $init = array-hash(a => 1, b => $b, c => 3);
        $init{'b'} := $b;
        @array := $init;
        %hash  := $init;
        make-iter($init.values »-» 1);
    }, 
    '04-init-from-pairs-and-positionals' => {
        $b = 2;
        my $init = array-hash(a => 1, 'b' =X> $b, c => 3);
        @array := $init;
        %hash  := $init;
        make-iter($init.values »-» 1);
    },
;

my %tests = 
    '01-basic' => {
        is %hash<a>, 1, 'hash a';
        is %hash<b>, 2, 'hash b';
        is %hash<c>, 3, 'hash c';

        is @array[.[0]].key, 'a', 'array 0 key';
        is @array[.[0]].value, 1, 'array 0 value';
        is @array[.[1]].key, 'b', 'array 1 key';
        is @array[.[1]].value, 2, 'array 1 value';
        is @array[.[2]].key, 'c', 'array 2 key';
        is @array[.[2]].value, 3, 'array 2 value';
    },
    '02-replace-hash' => {
        %hash<a> = 4;
        is %hash<a>, 4, 'hash a replaced';
        is @array[.()].value, 4, 'array 0 value replaced';
    },
    '03-append-hash' => {
        %hash<d> = 5;
        is %hash<d>, 5, 'hash d added';
        is @array[3].key, 'd', 'array d key added';
        is @array[3].value, 5, 'array d value added';
    },
    '04-replace-array' => {
        @array[.[1]] = 'e' =x> 6;
        is %hash{'b'}, Any, 'hash b removed';
        is %hash{'e'}, 6, 'hash e added';
    },
    '05-change-init-bound-var' => {
        $b = 7;
        is %hash<b>, 7, 'hash b modified';
        is @array[.[1]].value, 7, 'array b value modified';
    },
    '06-delete-hash-squashes-blanks' => {
        %hash<b> :delete;
        is @array.elems, 2, 'after hash delete elems == 2';
    },
    '07-delete-array-keeps-blanks' => {
        @array[1] :delete;
        is %hash.elems, 3, 'after array delete elems still == 3';
    },
    '08-perl' => {
        my @els = q["a" =x> 1], q["b" =x> 2], q["c" =x> 3];
        is @array.perl, q[array-hash(] ~ @els[.[0], .[1], .[2]].join(', ') ~ q[)], "array.perl";
        is %hash.perl, q[array-hash(] ~ @els[.[0], .[1], .[2]].join(', ') ~ q[)], "hash.perl";
    },
    '09-replace-earlier' => {
        @array[3] = 'b' =x> 8;
        is %hash<b>, 8, 'hash b changed';
        is @array[.[1]], KnottyPair:U, 'array 1 nullified';
    },
    '10-replace-later' => {
        if (.[1] == 0) {
            @array[0] = 'b' =x> 9;
            is %hash<b>, 9, 'hash b is changed';
            is @array[0].key, 'b', 'array 0 key same';
            is @array[0].value, 9, 'array 0 value changed';
        }
        else {
            @array[0] = 'b' =x> 9;
            is %hash<b>, 2, 'hash b is unchanged';
            is @array[0], KnottyPair:U, 'array 0 nullified';
        }
    },
    '11-bind-replace-earlier' => {
        @array[3] := 'b' =x> 8;
        is %hash<b>, 8, 'hash b changed';
        is @array[.[1]], KnottyPair:U, 'array 1 nullified';
    },
    '12-bind-replace-later' => {
        if (.[1] == 0) {
            @array[0] := 'b' =x> 9;
            is %hash<b>, 9, 'hash b is changed';
            is @array[0].key, 'b', 'array 0 key same';
            is @array[0].value, 9, 'array 0 value changed';
        }
        else {
            @array[0] := 'b' =x> 9;
            is %hash<b>, 2, 'hash b is unchanged';
            is @array[0], KnottyPair:U, 'array 0 nullified';
        }
    },
    '13-bind-key' => {
        %hash<a> := $b;
        $b = 10;
        is %hash<a>, 10, 'hash a changed';
        is %hash<b>, 10, 'hash b changed too';
        is @array[.[0]].value, 10, 'array 0 value changed';
        is @array[.[1]].value, 10, 'array 1 value changed';
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
        is $v, $b, 'deleted value is correct';
        is %hash.elems, 2, 'deleted hash shrunk by one elem';
        is @array.elems, 2, 'delete array shrunk by one elem too';
    },
    '17-delete-pos' => {
        my $p = @array[.[1]] :delete;
        is $p.key, 'b', 'deleted key is b';
        is $p.value, $b, 'deleted value is $b';
        if .[1] == 2 {
            is %hash.elems, 2, 'deleted hash shrunk by one elem';
            is @array.elems, 2, 'deleted array shrunk by one elem too';
        }
        else {
            is %hash.elems, 3, 'deleted hash did not shrink';
            is @array.elems, 3, 'deleted array did not shrink';
        }
        is @array[.[1]], KnottyPair, 'deleted array position is undef';
    },
    '18-push' => {
        @array.push: d => 11, 'e' =x> 12, b => 13, 'c' =x> 14;
        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[.[0]].key, 'a', 'array 0 key same';
        is @array[.[0]].value, 1, 'array 0 value same';
        is @array[.[1]].key, 'b', 'array 1 key same';
        is @array[.[1]].value, 13, 'array 1 value changed';
        is @array[.[2]], KnottyPair, 'array 2 nullified';

        my %remains = c => 14, d => 11, e => 12;
        for 3 .. 5 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }
    },
    '19-unshift' => {
        @array.unshift: d => 11, 'e' =x> 12, b => 13, 'c' =x> 14;
        is %hash<a>, 1, 'hash a same';
        is %hash<b>, $b, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        my $blanks = 1;
        my %remains = d => 11, e => 12;
        for 0 .. 2 -> $i {
            my $p = @array[$i];
            if !$p.defined {
                ok $blanks-- > 0, 'blank added';
            }
            else {
                my $v = %remains{ $p.key } :delete;
                is $v, $p.value, 'got an expected value';
            }
        }

        diag @array.perl;

        is @array[.[0] + 3].key, 'a', 'array 0 + 2 key same';
        is @array[.[0] + 3].value, 1, 'array 0 + 2 value same';
        is @array[.[1] + 3].key, 'b', 'array 1 + 2 key same';
        is @array[.[1] + 3].value, $b, 'array 1 + 2 value same';
        is @array[.[2] + 3].key, 'c', 'array 2 + 2 key same';
        is @array[.[2] + 3].value, 3, 'array 2 + 2 value same';
    },
    '20-splice-push' => {
        @array.splice: 3, 0, d => 11, 'e' =x> 12, b => 13, 'c' =x> 14;
        is %hash<a>, 1, 'hash a same';
        is %hash<b>, 13, 'hash b changed';
        is %hash<c>, 14, 'hash c changed';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        is @array[.[0]].key, 'a', 'array 0 key same';
        is @array[.[0]].value, 1, 'array 0 value same';
        is @array[.[1]], KnottyPair, 'array 1 nullified';
        is @array[.[2]], KnottyPair, 'array 2 nullified';

        my %remains = b => 13, c => 14, d => 11, e => 12;
        for 3 .. 6 -> $i {
            my $p = @array[$i];
            my $v = %remains{ $p.key } :delete;
            is $v, $p.value, 'got an expected value';
        }
    },
    '21-splice-unshift' => {
        @array.splice: 0, 0, d => 11, 'e' =x> 12, b => 13, 'c' =x> 14;
        is %hash<a>, 1, 'hash a same';
        is %hash<b>, $b, 'hash b same';
        is %hash<c>, 3, 'hash c same';
        is %hash<d>, 11, 'hash d added';
        is %hash<e>, 12, 'hash e added';

        my $blanks = 1;
        my %remains = d => 11, e => 12;
        for 0 .. 2 -> $i {
            my $p = @array[$i];
            if !$p.defined {
                ok $blanks-- > 0, 'blank added';
            }
            else {
                my $v = %remains{ $p.key } :delete;
                is $v, $p.value, 'got an expected value';
            }
        }

        diag @array.perl;

        is @array[.[0] + 4].key, 'a', 'array 0 + 2 key same';
        is @array[.[0] + 4].value, 1, 'array 0 + 2 value same';
        is @array[.[1] + 4].key, 'b', 'array 1 + 2 key same';
        is @array[.[1] + 4].value, $b, 'array 1 + 2 value same';
        is @array[.[2] + 4].key, 'c', 'array 2 + 2 key same';
        is @array[.[2] + 4].value, 3, 'array 2 + 2 value same';
    },
    # '22-splice-insert' => {
    # },
    # '23-splice-delete' => {
    # },
    # '24-splice-replace' => {
    # },
;

for %tests.kv -> $desc, &test {
    subtest {
        for %inits.kv -> $init-desc, &init {
            diag "init: $init-desc, test: $desc";
            my $o = init();
            subtest { temp $_ = $o; test() }, $init-desc;
        }
    }, $desc;
}


done;
