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
