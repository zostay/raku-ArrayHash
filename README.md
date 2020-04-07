NAME
====

ArrayHash - a data structure that is both Array and Hash

SYNOPSIS
========

    use ArrayHash;

    my @array := array-hash('a' => 1, 'b' => 2);
    my %hash := @array;

    @array[0].say; #> "a" => 1
    %hash<b> = 3;
    @array[1].say; #> "b" => 3;

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

An ArrayHash is both [Associative](Associative) and [Positional](Positional). This means you can use either a `@` sigil or a `%` sigil safely. However, there is some amount of conflicting tension between a Positional and Assocative data structure. An Associative object in Raku requires unique keys and has no set order. A Positional, on the other hand, has a set order, but no inherent uniqueness invariant. The primary way this tension is resolved depends on whether the operations you are performing are hashish or arrayish.

Whether an operation is hashish or arrayish ought to be obvious in most cases. For example, an array lookup using the `.[]` positional subscript is obviously arrayish whereas a key lookup using the `.{}` associative subscript is obviously hashish. Methods that are documented on `Hash` but not `Array` can be safely considered hashish and those that are documented on `Array` but not `Hash` as arrayish.

There are a few operations that overlap between them. Where there could be a difference in behavior, optional `:hash` and `:array` adverb are provided to allow you to select whether the operation acts like an [Hash](Hash) operation or an [Array](Array) operation (or sometimes a combination of the two). The default is usually `:hash` in those cases. I've tried to keep the choices intuitive, but check the documentation if there's any doubt.

Prior to v0.1.0 of this module, the way some functions behaved depended largely upon whether positional arguments or named arguments were used. However, as named arguments are not handled by most [Hash](Hash) functions in the way they were by this class, the practice has now been discontinued.

Last Pair Matters Rule
----------------------

In Raku, a [Hash](Hash) key will take on the value of the last key set. For example,

    my %hash = a => 1, a => 2;
    say %hash<a>; #> 2

This rule is preserved in [ArrayHash](ArrayHash), but with special semantics because of ordering:

    my %array-hash := array-hash('a' => 1, 'a' => 2);
    say %hash<a>; #> 2
    say %hash[0]; #> (Pair)
    say %hash[1]; #> a => 2

That is, an operation that manipulates the object in arrayish mode will preserve the positions of the objects, but will ensure that the last key set is the one preserved.

This rule may have some unexpected consequences if you are not aware of it. For example, considering the following `unshift` operations:

    my %a := array-hash('a' => 1);
    %a.unshift: 'a' => 10, 'a' => 20;
    say %a<a>; #> 1
    say %a[0]; #> (Pair)
    say %a[1]; #> (Pair)
    say %a[2]; #> a => 1

The `unshift` operation adds values to the front of the ArrayHash, but as we are adding a key that would be after, they get inserted as undefined [Pair](Pair)s instead to preserve the latest value rule.

The same last pair matters rule holds for all operations. Specifically, if you insert a new key at position A and the last pair with the same key is at position B:

  * The new value is preserved if A > B

  * The old value is preserved if A < B

The array-hash versus multi-hash
--------------------------------

While the last pair matters rule always holds that a later position of a key will override the earlier, it is possible to preserve the pairs that have been overridden. This class provides a variant on the `ArrayHash` via the [multi-hash#sub multi-hash](multi-hash#sub multi-hash) constructor that does this:

    my %mh := multi-hash('a' => 1, 'a' => 2);
    say %mh<a>; #> 2
    %mh[1]:delete;
    say %mh<a>; #> 1

As you can see it has some interesting properties. All valuesof a given key are preserved, but if you request the value using a key lookup, you will only receive the value with the largest positional index. If you iterate over the values as an array, you will be able to retrieve every value stored for that key.

This is not quite the same functionality as [Hash::MultiValue](Hash::MultiValue), which provides more tools for getting at these multiple values, but it has similar semantics.

Whether using an [array-hash#sub array-hash](array-hash#sub array-hash) or a [multi-hash#sub multi-hash](multi-hash#sub multi-hash), the operations all work nearly the same, but array values are not nullified in a `multi-hash` like they are in an `array-hash`. These are both represented by the same class, ArrayHash, but the [$.multivalued#method multivalued]($.multivalued#method multivalued) property is set to `True`.

[For future consideration: Consider adding a `has $.collapse` attribute or some such to govern whether a replaced value in a `$.multivalued` array hash is replaced with a type object or spiced out. Or perhaps change the `$.multivalued` into an enum of operational modes.]

[For future consideration: A parameterizable version of this class could be created with some sort of general keyable object trait rather than Pair.]

Methods
=======

method multivalued
------------------

    method multivalued() returns Bool:D

This setting determines whether the ArrayHash is a regular array-hash or a multi-hash. It is recommended that you use the [array-hash#sub array-hash](array-hash#sub array-hash) or [multi-hash#sub multi-hash](multi-hash#sub multi-hash) constructors instead of the [new method#method new](new method#method new).

method new
----------

    method new(Bool :$multivalued = False, *@pairs) returns ArrayHash:D

Constructs a new ArrayHash. This is not the preferred method of construction. It is recommended that you use [array-hash#sub array-hash](array-hash#sub array-hash) or [multi-hash#sub multi-hash](multi-hash#sub multi-hash) instead.

The `@pairs` passed may either be a list of [Pair](Pair) objects or pairs of other objects. If pass objects with a type other than [Pair](Pair), you must pass an even number of objects or you will end up with an [X::Hash::Store::OddNumber](X::Hash::Store::OddNumber) failure.

method of
---------

    method of() returns Mu:U

Returns what type of values are stored. This will always return a [Pair](Pair) type object.

method postcircumfix:<{ }>
--------------------------

    method postcircumfix:<{ }>(ArrayHash:D: $key) returns Mu

This provides the usual value lookup by key. You can use this to retrieve a value, assign a value, or bind a value. You may also combine this with the hash adverbs `:delete`, `:exists`, `:p`, `:k`, and `:v`.

method postcircumfix:<[ ]>
--------------------------

    method postcircumfix:<[ ]>(ArrayHash:D: Int:D $pos) returns Pair

This returns the value lookup by index. You can use this to retrieve the pair at the given index or assign a new pair or even bind a pair. It may be combined with the array adverbs `:delete`, `:exists`, `:p`, `:k`, and `:v`.

method push
-----------

    method push(ArrayHash:D: *@values) returns ArrayHash:D

Adds the given values onto the end of the ArrayHash. Because of the [Last Pair Matters Rule](#Last Pair Matters Rule), these values will always replace any existing values with matching keys.

method append
-------------

    method append(ArrayHash:D: +@values) returns ArrayHash:D

Adds the given values onto the end of the ArrayHash, just like the [push method#method push](push method#method push), but it flattens the lists given as arguments.

This modifies the ArrayHash in place and returns the new value.

method unshift
--------------

    method unshift(ArrayHash:D: *@values) returns ArrayHash:D

Adds the given values onto the front of the ArrayHash. Because of the [Last Pair Matters Rule](#Last Pair Matters Rule), these values will never replace any existing values in the data structure. In a multi-hash, these unshifted pairs will be put onto the front of the data structure without changing the primary keyed value. These insertions will be nullified if the hash is not multivalued.

    my @a := array-hash('a' => 1, 'b' => 2);
    @a.unshift 'a' => 3, 'b' => 4, 'c' => 5;
    @a.raku.say;
    #> array-hash((Pair), (Pair), "c" => 5, "a" => 1, "b" => 2);

    my @m := multi-hash('a' => 1, 'b' => 2);
    @m.push: 'a' => 3, 'b' => 4, 'c' => 5;
    @m.raku.say;
    #> multi-hash("a" => 3, "b" => 4, "c" => 5, "a" => 1, "b" => 2);

method prepend
--------------

    method prepend(ArrayHash:D: +@values) returns ArrayHash:D

Adds teh given values onto the beginning of the ArrayHash, just like the [unshift method#method unshift](unshift method#method unshift), but it flattens the lists given as arguments.

This modifies the ArrayHash in place and returns the new value.

method splice
-------------

    multi method splice(ArrayHash:D: &offset, Int(Cool) $size? *@values) returns ArrayHash:D
    multi method splice(ArrayHash:D: Int(Cool) $offset, &size, *@values) returns ArrayHash:D
    multi method splice(ArrayHash:D: &offset, &size, *@values) returns ArrayHash:D
    multi method splice(ArrayHash:D: Int(Cool) $offset = 0, Int(Cool) $size?, *@values) returns ArrayHash:D

This is a general purpose splice method for ArrayHash. As with [Array](Array) splice, it is able to perform most modification operations.

    my Pair $p;
    my @a := array-hash( ... );

    @a.splice: *, 0, "a" => 1;  # push
    $p = @a.splice: *, 1;       # pop
    @a.splice: 0, 0, "a" => 1;  # unshift
    $p = @a.splice: *, 1;       # shift
    @a.splice: 3, 1, "a" => 1;  # assignment
    @a.splice: 4, 1, "a" => $a; # binding
    @a.splice: 5, 1, Pair;      # deletion

    # And some operations that are uniqe to splice
    @a.splice: 1, 3;            # delete and squash
    @a.splice: 3, 0, "a" => 1;  # insertion

    # And the no-op, the $offset could be anything legal
    @a.splice: 4, 0;

The `$offset` is a point in the ArrayHash to perform the work. It is not an index, but a boundary between indexes. The 0th offset is just before index 0, the 1st offset is after index 0 and before index 1, etc.

The `$size` determines how many elements after `$offset` will be removed. These are returned as a new ArrayHash.

The `@values` are a list of new values to insert, which may be a list of [Pair](Pair)s or pairs other objects to be combined into [Pair](Pair)s. If empty, no new values are inserted. The number of elements inserted need not have any relationship to the number of items removed.

This method will fail with an [X::OutOfRange](X::OutOfRange) exception if the `$offset` or `$size` is out of range.

This method will fail with a [X::Hash::Store::OddNumber](X::Hash::Store::OddNumber) exception if an odd number of non-[Pair](Pair) objects is passed.

method sort
-----------

    method sort(ArrayHash:D: &by = &infix:<cmp>) returns Seq:D

Returns a sequence of [Pair](Pair)s from the ArrayHash sorted according to the given sort function, `&by`.

method unique
-------------

    method unique(ArrayHash:D:) returns ArrayHash:D

For a multivalued hash, this returns the same hash as a non-multivalued hash. Otherwise, it returns itself.

method rotor
------------

This is not implemented.

method pop
----------

    method pop(ArrayHash:D:) returns Pair

Takes the last element off the ArrayHash and returns it.

method shift
------------

    method shift(ArrayHash:D:) returns Pair

Takes the first element off the ArrayHash and returns it.

method values
-------------

    method values(
        Bool :$hash = False,
        Bool :$array = False,
    ) returns Seq:D

Returns all the values in insertion order. In hash mode, the default, the values of the hash are returned. In array mode, the pairs are returned, which may include Pair type objects for elements that have been deleted or nullified or never set. No combined hash/array mode is defined. The mode is selected by specifying the `:hash` or `:array` adverbs.

    my $ah = array-hash('a' => 1, 'b' => 2);
    say $ah.values;         #> (1 2)
    say $ah.values(:array); #> (a => 1 b => 2)

For a [multi-hash#sub multi-hash](multi-hash#sub multi-hash), every value will be iterated.

    my $mh = multi-hash('a' => 1, 'a' => 2);
    my $mh.values; #> (1 2)

method keys
-----------

    method keys(
        Bool :$hash = False,
        Bool :$array = False,
    ) returns Seq:D

Returns all the keys of the stored pairs in insertion order. In hash mode, the default, the values of the keys of the hash are turned. In array mode, the indexes of the array are returned.wNon combined array/hash mode is defined. The mode is selected using the `:hash` and `:array` adverbs.

    my $ah = array-hash('a' => 1, 'b' => 2);
    say $ah.keys;         #> (a b)
    say $ah.keys(:array); #> (0 1)

For a [multi-hash#sub multi-hash](multi-hash#sub multi-hash), every key will be iterated:

    my $mh = multi-hash('a' => 1, 'a' => 2);
    say $ah.keys; #> (a a)

method kv
---------

    method kv(
        Bool :$array = False,
        Bool :$hash = False,
    ) returns Seq:D

This returns an alternating sequence of keys and values. The sequence is always returned in insertion order.

In hash mode, the default, the keys will be the hash key and the value will be the hash value stored according to the [latest key matters rule#Latest Key Matters Rule](latest key matters rule#Latest Key Matters Rule). In array mode, the keys will be the array index and the value will be the [Pair](Pair) stored at that index. In combined hash/array mode, the result will be a triple alternation: array index, hash key, hash value. The mode is selected using the `:hash` and `:array` adverbs.

    my $ah = array-hash('a' => 10, 'b' => 20);
    say $ah.kv;                #> (a 10 b 20)
    say $ah.kv(:array);        #> (0 a => 10 1 b => 20)
    say $ah.kv(:array, :hash); #> (0 a 10 1 b 20)

For a [multi-hash#sub multi-hash](multi-hash#sub multi-hash), every key/value pair will be iterated:

    my $mh = multi-hash('a' => 1, 'a' => 2);
    say $mh.kv; #> a 1 a 2

method pairs
------------

    method pairs(
        Bool :$array = False,
        Bool :$hash = False,
    ) returns Seq:D

This returns a sequence of pairs stored in the ArrayHash. In hash mode, the default, only the defined hash key/value pairs are returned. In array mode, the array key/value pairs are returned. The keys will be the array indexes and the vvalues will be the hash key/value pair stored at each index.

    my $ah = array-hash('a' => 10, 'b' => 20);
    say $ah.pairs;        #> (a => 10 b => 20)
    say $ah.pairs(:array) #> (0 => a => 10 1 => b => 20)

method invert
-------------

    method invert() returns List:D

Not implemented.

method antipairs
----------------

    method antipairs() returns List:D

Not implemented.

method permutations
-------------------

Not implemented.

method raku
-----------

    multi method raku(ArrayHash:D:) returns Str:D

Returns the Raku code that could be used to recreate this list.

method gist
-----------

    multi method gist(ArrayHash:D:) returns Str:D

Returns the Raku code that could be used to recreate this list, up to the 100th element.

method fmt
----------

    method fmt($format = "%s\t%s", $sep = "\n") returns Str:D

Prints the contents of the ArrayHash using the given format and separator.

method reverse
--------------

    method reverse(ArrayHash:D:) returns ArrayHash:D

Returns the ArrayHash, but with pairs inserted in reverse order.

method rotate
-------------

    method rotate(ArrayHash:D: Int $n = 1) returns ArrayHash:D

Returns the ArrayHash, but with the pairs inserted rotated by `$n` elements.

method elems
------------

    method elems(ArrayHash:D:) returns Int:D

Returns the number of elements stored in the ArrayHash.

method end
----------

    method end(ArrayHash:D:) returns Int:D

Returns the index of the last element stored in the ArrayHash.

method flat
-----------

    method flat(ArrayHash:D:) returns Seq:D

Returns a sequence of the Pairs stored in the ArrayHash. As the items stored are always [Pair](Pair)s, this will always be functionally equivalent to the [pairs method#method pairs](pairs method#method pairs).

method pick
-----------

    multi method pick(ArrayHash:D:) returns Pair
    multi method pick(ArrayHash:D: Whatever) returns Seq:D
    multi method pick(ArrayHash:D: $count) returns Seq:D

When called with no arguments, returns a random [Pair](Pair) stored in the ArrayHash. It will return Nil if the ArrayHash is empty.

When called with arguments, it will return a sequence of 0 or more unique items stored in the ArrayHash in random order. If [Whatever](Whatever) is passed, all Pairs will be reutrned from the sequence in random order.

method roll
-----------

    multi method roll(ArrayHash:D:) returns Pair
    multi method roll(ArrayHash:D: $count) returns Seq:D

When called with no arguemnts, returns a random [Pair](Pair) stored in the ArrayHash. It will return Nil if the ArrayHash is empty.

When called with a numeric `$count`, it will return `$count` Pairs which are pulled random from the elements stored in the ArrayHash. The items pulled are not guaranteed to be unique.

method reduce
-------------

    method reduce(ArrayHash:D: &with)

Performs inductive iteration over the [Pair](Pair)s stored in the ArrayHash.

For an empty ArrayHash, the given code will be called once with no arguments and the return value of that code is returned by the reduce method.

For a single item ArrayHash, the given code will be called once with a single argument, the single item stored, and the return value of that code is returned by the reduce method.

For a two item ArrayHash, the given code will be called once with two arguments, the first and second items stored, and the return value of that code is returned by the reduce method.

For a three or more item ArrayHash, the given code will be called two or more times. The first call will receive the first two elements of the ArrayHash as arguments. All subsequent calls will receive the return of the previous call as the first argument and the next ArrayHash element as the second argument. The final return value of the `&with` code will be returned from the reduce method.

method produce
--------------

    method produce(ArrayHash:D: &with) returns Seq:D

This method operates in precisely the same manner as the [reduce method#method reduce](reduce method#method reduce), but instead of only returning the result from the final call to `&with`, it returns a sequence that iterates through every value returned by calls to `&with`.

method combinations
-------------------

    multi method combinations(ArrayHash:D: Int() $of) returns Seq:D
    multi method combinations(ArrayHash:D: Iterable:D $of = 0..*) returns Seq:D

This method returns a seqeuence of the requested combinations of Pairs stored in the ArrayHash.

method join
-----------

    method join(ArrayHash:D: $sep = '') returns Str

Concatenates the [Pair](Pair)s stored in the ArrayHash into a string using the given separator, `$sep`.

method map
----------

    method map(ArrayHash:D: &block) returns Seq:D

Returns a sequence where the result of the operation of `&block` being applied to each [Pair](Pair) in the ArrayHash is returned.

method grep
-----------

    method grep(ArrayHash:D: Mu $matcher, :$k, :$v, :$kv, :$p) returns Seq:D

Returns a sequence containing only the values in the ArrayHash that match the given `$matcher`. By default, the result will be the [Pair](Pair)s matched, but by supplying an adverb, you can modify which type of information is returned:

  * `:k` causes only the keys to be returned.

  * `:v` causes only the values to be returned.

  * `:kv` causes the keys and values to be returned in an alternating sequence.

  * `:p` causes the pairs to be returned (the default).

method first
------------

    method first(ArrayHash:D: Mu $matcher?, :$k, :$v, :$kv, :$p, :$end)

Returns the first [Pair](Pair) from the ArrayHash that matches the given matcher, `$matcher` (or just the first element if no matcher is provided). The return value can be modified by using the `:k`, `:v`, `:kv`, and `:p` adverbs. See the [grep method#method grep](grep method#method grep) for details. Instead of matching from the front of the list, it can match from the end if the `:end` adverb is given.

method head
-----------

    method head(ArrayHash:D:) returns Pair
    method head(ArrayHash:D: $n) returns Seq:D
    method head(ArrayHash:D: &c) returns Seq:D

Returns the [Pair](Pair)s from the front of the ArrayHash. With no arguments, it returns the first [Pair](Pair) or `Nil` if the ArrayHash is empty.

If a number is given, then a sequence of that many items from the front of the ArrayHash is returned.

If a [WhateverCode](WhateverCode) range is given, e.g., `*-3`, then all the items from front of the list until that [WhateverCode](WhateverCode) range starts from the back is returned.

method tail
-----------

    method tail(ArrayHash:D:) returns Pair
    method tail(ArrayHash:D: $n) returns Seq:D
    method tail(ArrayHash:D: &c) returns Seq:D

Returns the [Pair](Pair)s from the back of the ArrayHash. With no arguments, it returns the last [Pair](Pair) or `Nil` if the ArrayHash is empty.

If a number is given, then a sequence of that many items from the back of the ArrayHash is returned.

If a [WhateverCode](WhateverCode) range is given, e.g., `*-3`, then all the items from back of the list until that [WhateverCode](WhateverCode) range starts from the front is returned.

method Array
------------

    method Array(ArrayHash:D:) returns Array:D

Returns an [Array](Array) object containing the pairs in the ArrayHash.

method Hash
-----------

    method Hash(ArrayHash:D:) returns Hash:D

Returns a [Hash](Hash) object containing the pairs of the ArrayHash. If this is a multi-hash, any keys with multiple values will be collapsed according to the [Last Pair Matters Rule#Last Pair Matters Rule](Last Pair Matters Rule#Last Pair Matters Rule).

method Bool
-----------

    method Bool(ArrayHash:D:) returns Bool:D

Returns `True` if there are one or more items stored in the object. Returns `False` if the ArrayHash is empty.

method Int
----------

    method Int(ArrayHash:D:) returns Int:D

Returns the number of elements stored in the ArrayHash.

method Numeric
--------------

    method Numeric(ArrayHash:D:) returns Numeric:D

Returns the number of elements stored in the ArrayHash.

method Str
----------

    method Str(ArrayHash:D:) returns Str:D

Returns a string representation of the ArrayHash. This will include a string representation of all the [Pairs](Pairs) stored with a space between them.

method Capture
--------------

    method Capture(ArrayHash:D:) returns Capture:D

Returns a [Capture](Capture) which will have the positional arguments set to the values of the elements of this ArrayHash.

method Supply
-------------

    method Supply(ArrayHash:D:) returns Supply:D

Returns a [Supply](Supply), which emits the Pair elements of the ArrayHash in order.

sub array-hash
--------------

    sub array-hash(*@a) returns ArrayHash:D where { !*.multivalued }

Constructs a new ArrayHash with multivalued being false, containing the given initial pairs in the given order.

sub multi-hash
--------------

    sub multi-hash(*@a) returns ArrayHash:D where { *.multivalued }

Constructs a new multivalued ArrayHash containing the given initial pairs in the given order.

