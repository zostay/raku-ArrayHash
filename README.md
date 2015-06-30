NAME
====

ArrayHash - a data structure that is both Array and Hash

SYNOPSIS
========

    use ArrayHash;

    my @array := array-hash('a' =x> 1, 'b' => 2);
    my %hash := @array;

    @array[0].say; #> "a" =x> 1
    %hash<b> = 3;
    @array[1].say; #> "b" =x> 3;

    # The order of the keys is preserved
    for %hash.kv -> $k, $v { 
        say "$k: $v";
    }

    # Note, the special ip operation, here is a significant interface
    # difference from a usual array, .kv is always a key-value alternation,
    # there's also an .ikv:
    for @array.ip -> $i, $p {
        say "$p.key: $p.value is #$i";
    }

DESCRIPTION
===========

**Experimental:** The API here is experimental. Some important aspects of the API may change without warning.

You can think of this as a [Hash](Hash) that always iterates in insertion order or you can think of this as an [Array](Array) of [Pair](Pair)s with fast lookups by key. Both are correct, though it really is more hashish than arrayish because of the Pairs, which is why it's an ArrayHash and not a HashArray. 

This class uses [KnottyPair](KnottyPair) internally, rather than plain old Pairs, but you can usually use either when interacting with objects of this class.

An ArrayHash is both Associative and Positional. This means you can use either a `@` sigil or a `%` sigil safely. However, there is some amount of conflicting tension between a [Positional](Positional) and [Assocative](Assocative) data structure. An Associative object in Perl requires unique keys and has no set order. A Positional, on the othe rhand, is a set order, but no inherent uniqueness invariant. The primary way this tension is resolved depends on whether the operations you are performing are hashish or arrayish.

For example, consider this `push` operation:

    my @a := array-hash('a' =x> 1, 'b' =x> 2);
    @a.push: 'a' =x> 3, b => 4;
    @a.perl.say;
    #> array-hash(KnottyPair, "b" =x> 4, "a" =x> 3);

Here, the `push` is definitely an arrayish operation, but it is given both an arrayish argument, `'a' =x> 3`, and a hashish argument `b => 4`. Therefore, the [KnottyPair](KnottyPair) keyed with `"a"` is pushed onto the end of the ArrayHash and the earlier value is nullified. The [Pair](Pair) keyed with `"b"` performs a more hash-like operation and replaces the value on the existing pair.

Now, compare this to a similar `unshit` operation:

    my @a := array-hash('a' =x> 1, 'b' =x> 2);
    @a.unshift: 'a' =x> 3, b => 4;
    @a.perl.say;
    #> array-hash(KnottyPair, 'a' =x> 1, 'b' =x> 2);

What happened? Why didn't the values changed and where did this extra [KnottyPair](KnottyPair) come from? Again, `unshift` is arrayish and we have an arrayish and a hashish argument, but this time we demonstrate another normal principle of Perl hashes that is enforced, which is, when dealing with a list of [Pair](Pair)s, the latest Pair is the one that bequeaths its value to the hash. That is,

    my %h = a => 1, a => 2;
    say "a = %h<a>";
    #> a = 2

Since an [ArrayHash](ArrayHash) maintains its order, this rule always applies. A value added near the end will win over a value at the beginning. Adding a value near the beginning will lose to a value nearer the end.

So, returning to the `unshift` example above, the arrayish value with key `"a"` gets unshifted to the front of the array, but immediately nullified because of the later value. The hashish value with key `"b"` sees an existing value for the same key and the existing value wins since it would come after it. 

The same rule holds for all operations: If the key already exists, but before the position the value is being added, the new value wins. If the key already exists, but after the position we are inserting, the old value wins.

For a regular ArrayHash, the losing value will either be replaced, if the operation is hashish, or will be nullified, if the operation is arrayish. 

This might not always be the desired behavior so this module also provides the multivalued ArrayHash, or multi-hash:

    my @a := multi-hash('a' =x> 1, 'b' =x> 2);
    @a.push: 'a' =x> 3, b => 4;
    @a.perl.say;
    #> multi-hash('a' =x> 1, "b" =x> 4, "a" =x> 3);

The operations all work the same, but array values are not nullified and it is find for there to be multiple values in the array. This is the same class, ArrayHash, but the [has $.multivalued](has $.multivalued) property is set to true.

[Conjecture: Consider adding a `has $.collapse` attribute or some such to govern whether a replaced value in a `$.multivalued` array hash is replaced with a type object or spiced out. Or perhaps change the `$.multivalued` into an enum of operational modes.]

[Conjecture: In the future, a parameterizable version of this class could be created with some sort of general keyable object trait rather than KnottyPair.]

Attributes
==========

has $.multivalued
-----------------

    has $.multivalued = False;

This determines whether the ArrayHash is a regular array-hash or a multi-hash. Usually, you will use the [sub array-hash](sub array-hash) or [sub multi-hash](sub multi-hash) constructors rather than setting this directly.

method new
----------

    method new(Bool :multivalued = False, *@a, *%h) returns ArrayHash:D

Constructs a new ArrayHash. This is not the preferred method of construction. You should use [sub array-hash](sub array-hash) or [sub multi-hash](sub multi-hash) instead.

method of
---------

    method of() returns Mu:U

Returns what type of values are stored. This always returns a [KnottyPair](KnottyPair) type object.

method postcircumfix:<{ }>
--------------------------

    method postcircumfix:<( )>(ArrayHash:D: $key) returns Mu

This provides the usual value lookup by key. You can use this to retrieve a value, assign a value, or bind a value. You may also combine this with the hash adverbs `:delete` and `:exists`.

method postcircumfix:<[ ]>
--------------------------

    method postcircumfix:<[ ]>(ArrayHash:D: Int:D $pos) returns KnottyPair

This returns the value lookup by index. You can use this to retrieve the pair at the given index or assign a new pair or even bind a pair. It may be combined with the array adverts `:delete` and `:exists` as well.
