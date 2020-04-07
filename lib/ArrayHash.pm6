use v6;

unit class ArrayHash:ver<0.4.1>:auth<github:zostay> does Associative does Positional;

has %!hash;
has Pair @!array handles <
    elems Bool Int end Numeric Str
    flat list Capture Supply
    pick roll reduce combinations
    join map grep first head
    tail sort produce
>;

has Bool $.multivalued = False;

# TODO make this a macro...
sub want($key) {
    & = { .defined && .key eqv $key }
}

method new(*@a, Bool :$multivalued = False)  {
    my $self = self.bless(:$multivalued);
    $self.push: |@a;
    $self
}

submethod BUILD(:$!multivalued) { self }

method of() {
    self.Positional::of();
}

method !clear-before($pos, $key) {
    my @pos = @!array[0 .. $pos - 1].grep(want($key), :k);
    @!array[@pos] :delete;
}

method !found-after($pos, $key) returns Bool {
    @!array[$pos + 1 .. @!array.end].first(want($key), :k) ~~ Int
}

method AT-KEY(ArrayHash:D: $key) {
    %!hash{$key}
}

method AT-POS(ArrayHash:D: $pos) returns Pair {
    @!array[$pos];
}

method ASSIGN-KEY(ArrayHash:D: $key, $value is copy) {
    # Newly assigned key must be the same container in both array and hash
    POST { %!hash{$key} =:= @!array[ @!array.first(want($key), :k, :end) ].value }

    if %!hash{$key} :exists {
        %!hash{$key} = $value;

        CATCH {
            # Handle the case where value is immutable
            when X::Assignment::RO {
                %!hash{$key} := $value;
                @!array[ @!array.first(want($key), :k, :end) ] := $key => $value;
            }
        }
    }
    else {
        @!array.push: $key => $value;
        %!hash{$key} := $value;
    }
}

method ASSIGN-POS(ArrayHash:D: $pos, Pair $pair) {
    # array-hash must contain the new pair no more than one times alrady
    PRE  { $!multivalued || @!array.grep(want($pair.key)).elems <= 1 }

    # array-hash must contain each key zero or one times
    POST { $!multivalued || @!array.grep(want($pair.key)).elems <= 1 }

    # Newly assigned key must be the same container in both array and hash
    POST { %!hash{$pair.key} =:= @!array[ @!array.first(want($pair.key), :k, :end) ].value }

    if !$!multivalued && (%!hash{ $pair.key } :exists) {
        self!clear-before($pos, $pair.key);
    }

    if @!array[$pos] :exists && @!array[$pos].defined {
        %!hash{ @!array[$pos].key } :delete;
    }

    my $orig = @!array[ $pos ];

    if self!found-after($pos, $pair.key) {
        if $!multivalued {
            @!array[ $pos ] := $pair;
        }
        else {
            @!array[ $pos ] := Pair;
        }
    }
    else {
        # Make sure the stored value is a key => $var binding
        my $v := $pair.value;
        my $p := $pair.key => $v;

        %!hash{ $p.key } := $p.value;
        @!array[ $pos ]  := $p;
    }

    if $!multivalued && $orig.defined {
        my $npos = @!array.first(want($orig.key), :k, :end);
        if $npos ~~ Int {
            %!hash{ $orig.key } := @!array[$npos].value;
        }
    }

    $pair;
}

method BIND-KEY(ArrayHash:D: $key, Mu \value) is raw {
    # Newly assigned key must be the same container in both array and hash
    POST { %!hash{$key} =:= @!array.reverse.first(want($key)).value }

    if %!hash{$key} :exists {
        %!hash{$key} := value;
        my $pos = @!array.first(want($key), :k, :end);
        @!array[$pos] := $key => value;
    }
    else {
        %!hash{$key} := value;
        @!array.push: $key => value;
    }
}

method BIND-POS(ArrayHash:D: $pos, Pair:D \pair) {
    # array-hash must contain the new pair no more than one times already
    PRE  { $!multivalued || @!array.grep(want(pair.key)).elems <= 1 }

    # array-hash may contain each key zero or one times
    POST { $!multivalued || @!array.grep(want(pair.key)).elems <= 1 }

    # Newly assigned key must be the same container in both array and hash
    POST { %!hash{pair.key} =:= @!array.reverse.first(want(pair.key)).value }

    if !$!multivalued && (%!hash{ pair.key } :exists) {
        self!clear-before($pos, pair.key);
    }

    if @!array[$pos] :exists && @!array[$pos].defined {
        %!hash{ @!array[$pos].key } :delete;
    }

    if self!found-after($pos, pair.key) {
        if $!multivalued {
            @!array[ $pos ] := pair;
        }
        else {
            @!array[ $pos ] := Pair;
        }
    }
    else {
        %!hash{ pair.key } := pair.value;
        @!array[ $pos ]    := pair;
    }
}

method EXISTS-KEY(ArrayHash:D: $key) {
    %!hash{$key} :exists;
}

method EXISTS-POS(ArrayHash:D: $pos) {
    @!array[$pos] :exists;
}

method DELETE-KEY(ArrayHash:D: $key) {
    # Deleted key must not exist in hash
    POST { %!hash{$key} :!exists }

    # Deleted key must not exist in array
    POST { @!array.first(want($key), :k) ~~ Nil }

    if %!hash{$key} :exists {
        my @pos = @!array.grep(want($key), :k);
        @!array[ @pos ] :delete;
    }

    %!hash{$key} :delete;
}

method DELETE-POS(ArrayHash:D: $pos) returns Pair {
    my Pair $pair;

    # Deleted value must be undef in array
    POST { @!array[$pos] ~~ Pair:U }

    # deleted pair from array-hash must not exist in array
    POST {
        $pair.defined && !$!multivalued ??
            @!array.first(want($pair.key), :k) ~~ Nil
        !! True
    }

    # deleted pair from multi-hash array and hash must agree on whether the pair
    # has been completely removed or just partially removed
    POST {
        $pair.defined && $!multivalued ??
            (@!array.first(want($pair.key), :k) ~~ Int
                and %!hash{ $pair.key } :exists)
         ^^ (@!array.first(want($pair.key), :k) ~~ Nil
                and %!hash{ $pair.key } :!exists)
        !! True
    }

    if $pair = @!array[ $pos ] :delete {
        %!hash{ $pair.key } :delete;

        if $!multivalued && self!found-after($pos, $pair.key) {
            my $next = @!array.first(want($pair.key));
            %!hash{ $pair.key } := $next.value;
        }
    }

    $pair;
}

method !values-to-pairs(\values) {
    gather {
        my ($k, $n);

        for values.kv -> $i, $v {
            $n = $i;

            with $k {
                take $k => $=$v;
                $k = Nil;
            }
            elsif $v ~~ Pair {
                take $v.key => $=$v.value;
            }
            else {
                $k = $v;
            }
        }

        with $k {
            fail X::Hash::Store::OddNumber.new(
                found => $n,
                last  => $k,
            );
        }
    }
}

method push(ArrayHash:D: *@values) returns ArrayHash:D {
    for self!values-to-pairs(@values) -> $pair {
        self.ASSIGN-POS(@!array.elems, $pair);
    }
    self
}

method append(ArrayHash:D: +@values) returns ArrayHash:D {
    self.push: |@values;
}

method unshift(ArrayHash:D: *@values) returns ArrayHash:D {
    for self!values-to-pairs(@values).reverse.kv -> $i, $p {
        if !$!multivalued and %!hash{ $p.key } :exists {
            @!array.unshift: Pair;
        }
        else {
            @!array.unshift: $p;
            %!hash{ $p.key } := $p.value
                unless self!found-after($i, $p.key);
        }
    }

    self
}

method prepend(ArrayHash:D: +@values) returns ArrayHash:D {
    self.unshift: |@values;
}

multi method splice(ArrayHash:D: &offset, Int(Cool) $size?, *@values) returns ArrayHash:D {
    callsame(offset(self.elems), $size, |@values)
}

multi method splice(ArrayHash:D: Int(Cool) $offset, &size, *@values) returns ArrayHash:D {
    callsame($offset, size(self.elems - $offset), |@values)
}

multi method splice(ArrayHash:D: &offset, &size, *@values) returns ArrayHash:D {
    my $o = offset(self.elems);
    callsame($o, size(self.elems - $o), |@values)
}

multi method splice(ArrayHash:D: Int(Cool) $offset = 0, Int(Cool) $size?, *@values) returns ArrayHash:D {
    $size //= self.elems - ($offset min self.elems);

    unless 0 <= $offset <= self.elems {
        X::OutOfRange.new(
            what  => 'offset argument to ArrayHash.splice',
            got   => $offset,
            range => ^self.elems,
        ).fail;
    }

    unless 0 <= $size <= self.elems - $offset {
        X::OutOfRange.new(
            what  => 'size argument to ArrayHash.splice',
            got   => $size,
            range => ^(self.elems - $offset),
        ).fail;
    }

    # Compile the list of replacements, nullifying those that have keys
    # matching pairs later in the list (the later items are kept).
    my @repl;
    for self!values-to-pairs(@values) -> $pair {
        my $p = do given $pair {
            when Pair:D { $pair }
            when .defined { $pair.key => $pair.value }
            default { Pair }
        };

        my $pos = do if !$!multivalued && $p.defined {
            @!array[$offset + $size .. @!array.end].first(want($p.key), :k);
        }
        else { Nil }

        @repl.push($pos ~~ Int ?? Pair !! $p);
    }

    # Splice the array
    my @ret = @!array.splice($offset, $size, @repl);

    # Delete the removed keys
    for @ret -> $p {
        %!hash{ $p.key } :delete
            if !$!multivalued || !@!array.first(want($p.key));
    }

    # Replace hash elements with new values
    for @repl -> $p {
        %!hash{ $p.key } := $p.value
            if $p.defined && !self!found-after($offset + @repl.elems - 1, $p.key);
    }

    # Nullify earlier values that have just been replaced
    unless $!multivalued {
        for @!array[0 .. $offset - 1].kv -> $i, $p {
            @!array[$i] :delete
                if $p.defined && @repl.first(want($p.key)).defined;
        }
    }

    # Return the removed elements
    return ArrayHash.new(:$!multivalued).push(|@ret);
}

method unique(ArrayHash:D:) returns ArrayHash:D {
    if $!multivalued {
        array-hash(self.pairs)
    }
    else {
        self
    }
}

method rotor(ArrayHash:D:) {
    die "not implemented";
}

method pop(ArrayHash:D:) returns Pair {
    self.DELETE-POS(@!array.end)
}

method shift(ArrayHash:D) returns Pair {
    my $head;
    $head = @!array.shift
        andthen %!hash{ $head.key } :delete;
    return $head;
}

method values(
    Bool :$array,
    Bool :$hash,
) returns Seq:D {
    if $array {
        @!array.values
    }
    else {
        @!array.grep({ .defined }).map({ .value })
    }
}

method keys(
    Bool :$array,
    Bool :$hash,
) returns Seq:D {
    if $array {
        @!array.keys
    }
    else {
        @!array.grep({ .defined }).map({ .key })
    }
}

method kv(
    Bool :$array,
    Bool :$hash,
) returns Seq:D {
    if $array && $hash {
        @!array.kv.map({ .defined && Pair ?? .kv !! $_ }).flat
    }
    elsif $array {
        @!array.kv
    }
    else {
        @!array.map({ .kv }).flat
    }
}

method pairs(
    Bool :$array,
    Bool :$hash,
) returns Seq:D {
    if $array {
        @!array.pairs
    }
    else {
        @!array.grep({ .defined })
    }
}

method invert() returns Seq:D {
    die 'not implemented'
}

method antipairs() returns Seq:D {
    die 'not implemented'
}

method permutations() returns Seq:D {
    die 'not yet implmeneted'
}

multi method raku(ArrayHash:D:) returns Str:D {
    my $type = $!multivalued ?? 'multi-hash' !! 'array-hash';
    $type ~ '(' ~ @!array.map({ .defined ?? .raku !! 'Pair' }).join(', ') ~ ')'
}

multi method perl(ArrayHash:D:) returns Str:D {
    my $type = $!multivalued ?? 'multi-hash' !! 'array-hash';
    $type ~ '(' ~ @!array.map({ .defined ?? .perl !! 'Pair' }).join(', ') ~ ')'
}

multi method gist(ArrayHash:D:) returns Str:D {
    my $type = $!multivalued ?? 'multi-hash' !! 'array-hash';
    $type ~ '(' ~ do for @!array -> $elem {
        given ++$ {
            when 101 { '...' }
            when 102 { last }
            default { $elem.gist }
        }
    }.join(', ') ~ ')'
}

method fmt($format = "%s\t%s", $sep = "\n") returns Str:D {
    do for @!array -> $e {
        $e.fmt($format)
    }.join($sep)
}

method reverse(ArrayHash:D:) returns ArrayHash:D {
    ArrayHash.new(:$!multivalued).push(|@!array.reverse)
}

method rotate(ArrayHash:D: Int $n = 1) returns ArrayHash:D {
    ArrayHash.new(;$!multivalued).push(|@!array.rotate($n))
}

method clone(ArrayHash:D:) returns ArrayHash:D {
    ArrayHash.new(:$!multivalued, |@!array.clone, |%!hash.clone);
}

method Array(ArrayHash:D:) returns Array:D { @!array.clone }
method Hash(ArrayHash:D:) returns Hash:D { %!hash.clone }

method categorize(|) {
    die 'not implemented';
}

method classify(|) {
    die 'not implemented';
}

method eager(|) {
    die 'not implemented';
}

method batch(|) {
    die 'not implemented';
}

method cross(|) {
    die 'not implemented';
}

method zip(|) {
    die 'not implemented';
}

method roundrobin(|) {
    die 'not implemented';
}

method sum(|) {
    die 'not implemented';
}

method Set(|) {
    die 'not implemented';
}

sub cmp(|) {
    die 'not implemented';
}

sub classify-list(|) {
    die 'not implemented';
}

sub categorize-list(|) {
    die 'not implemented';
}



our sub array-hash(|c) is export { ArrayHash.new(|c) }
our sub multi-hash(|c) is export { ArrayHash.new(|c, :multivalued) }

=begin pod

=NAME ArrayHash - a data structure that is both Array and Hash

=begin SYNOPSIS

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

=end SYNOPSIS

=head1 DESCRIPTION

B<Experimental:> The API here is experimental. Some important aspects of the API may change without warning.

You can think of this as a L<Hash> that always iterates in insertion order or you can think of this as an L<Array> of L<Pair>s with fast lookups by key. Both are correct, though it really is more hashish than arrayish because of the Pairs, which is why it's an ArrayHash and not a HashArray.

An ArrayHash is both L<Associative> and L<Positional>. This means you can use either a C<@> sigil or a C<%> sigil safely. However, there is some amount of conflicting tension between a Positional and Assocative data structure. An Associative object in Raku requires unique keys and has no set order. A Positional, on the other hand, has a set order, but no inherent uniqueness invariant. The primary way this tension is resolved depends on whether the operations you are performing are hashish or arrayish.

Whether an operation is hashish or arrayish ought to be obvious in most cases. For example, an array lookup using the C<.[]> positional subscript is obviously arrayish whereas a key lookup using the C<.{}> associative subscript is obviously hashish. Methods that are documented on C<Hash> but not C<Array> can be safely considered hashish and those that are documented on C<Array> but not C<Hash> as arrayish.

There are a few operations that overlap between them. Where there could be a difference in behavior, optional C<:hash> and C<:array> adverb are provided to allow you to select whether the operation acts like an L<Hash> operation or an L<Array> operation (or sometimes a combination of the two). The default is usually C<:hash> in those cases. I've tried to keep the choices intuitive, but check the documentation if there's any doubt.

Prior to v0.1.0 of this module, the way some functions behaved depended largely upon whether positional arguments or named arguments were used. However, as named arguments are not handled by most L<Hash> functions in the way they were by this class, the practice has now been discontinued.

=head2 Last Pair Matters Rule

In Raku, a L<Hash> key will take on the value of the last key set. For example,

    my %hash = a => 1, a => 2;
    say %hash<a>; #> 2

This rule is preserved in L<ArrayHash>, but with special semantics because of ordering:

    my %array-hash := array-hash('a' => 1, 'a' => 2);
    say %hash<a>; #> 2
    say %hash[0]; #> (Pair)
    say %hash[1]; #> a => 2

That is, an operation that manipulates the object in arrayish mode will preserve the positions of the objects, but will ensure that the last key set is the one preserved.

This rule may have some unexpected consequences if you are not aware of it. For example, considering the following C<unshift> operations:

    my %a := array-hash('a' => 1);
    %a.unshift: 'a' => 10, 'a' => 20;
    say %a<a>; #> 1
    say %a[0]; #> (Pair)
    say %a[1]; #> (Pair)
    say %a[2]; #> a => 1

The C<unshift> operation adds values to the front of the ArrayHash, but as we are adding a key that would be after, they get inserted as undefined L<Pair>s instead to preserve the latest value rule.

The same last pair matters rule holds for all operations. Specifically, if you insert a new key at position A and the last pair with the same key is at position B:

=item The new value is preserved if A > B

=item The old value is preserved if A < B

=head2 The array-hash versus multi-hash

While the last pair matters rule always holds that a later position of a key will override the earlier, it is possible to preserve the pairs that have been overridden. This class provides a variant on the C<ArrayHash> via the L<multi-hash#sub multi-hash> constructor that does this:

    my %mh := multi-hash('a' => 1, 'a' => 2);
    say %mh<a>; #> 2
    %mh[1]:delete;
    say %mh<a>; #> 1

As you can see it has some interesting properties. All valuesof a given key are preserved, but if you request the value using a key lookup, you will only receive the value with the largest positional index. If you iterate over the values as an array, you will be able to retrieve every value stored for that key.

This is not quite the same functionality as L<Hash::MultiValue>, which provides more tools for getting at these multiple values, but it has similar semantics.

Whether using an L<array-hash#sub array-hash> or a L<multi-hash#sub multi-hash>, the operations all work nearly the same, but array values are not nullified in a C<multi-hash> like they are in an C<array-hash>. These are both represented by the same class, ArrayHash, but the L<$.multivalued#method multivalued> property is set to C<True>.

[For future consideration: Consider adding a C<has $.collapse> attribute or some such to govern whether a replaced value in a C<$.multivalued> array hash is replaced with a type object or spiced out. Or perhaps change the C<$.multivalued> into an enum of operational modes.]

[For future consideration: A parameterizable version of this class could be created with some sort of general keyable object trait rather than Pair.]

=head1 Methods

=head2 method multivalued

    method multivalued() returns Bool:D

This setting determines whether the ArrayHash is a regular array-hash or a multi-hash. It is recommended that you use the L<array-hash#sub array-hash> or L<multi-hash#sub multi-hash> constructors instead of the L<new method#method new>.

=head2 method new

    method new(Bool :$multivalued = False, *@pairs) returns ArrayHash:D

Constructs a new ArrayHash. This is not the preferred method of construction. It is recommended that you use L<array-hash#sub array-hash> or L<multi-hash#sub multi-hash> instead.

The C<@pairs> passed may either be a list of L<Pair> objects or pairs of other objects. If pass objects with a type other than L<Pair>, you must pass an even number of objects or you will end up with an L<X::Hash::Store::OddNumber> failure.

=head2 method of

    method of() returns Mu:U

Returns what type of values are stored. This will always return a L<Pair> type object.

=head2 method postcircumfix:<{ }>

    method postcircumfix:<{ }>(ArrayHash:D: $key) returns Mu

This provides the usual value lookup by key. You can use this to retrieve a value, assign a value, or bind a value. You may also combine this with the hash adverbs C<:delete>, C<:exists>, C<:p>, C<:k>, and C<:v>.

=head2 method postcircumfix:<[ ]>

    method postcircumfix:<[ ]>(ArrayHash:D: Int:D $pos) returns Pair

This returns the value lookup by index. You can use this to retrieve the pair at the given index or assign a new pair or even bind a pair. It may be combined with the array adverbs C<:delete>, C<:exists>, C<:p>, C<:k>, and C<:v>.

=head2 method push

    method push(ArrayHash:D: *@values) returns ArrayHash:D

Adds the given values onto the end of the ArrayHash. Because of the L<#Last Pair Matters Rule>, these values will always replace any existing values with matching keys.

=head2 method append

    method append(ArrayHash:D: +@values) returns ArrayHash:D

Adds the given values onto the end of the ArrayHash, just like the L<push method#method push>, but it flattens the lists given as arguments.

This modifies the ArrayHash in place and returns the new value.

=head2 method unshift

    method unshift(ArrayHash:D: *@values, *%values) returns ArrayHash:D

Adds the given values onto the front of the ArrayHash. Because of the L<#Last Pair Matters Rule>, these values will never replace any existing values in the data structure. In a multi-hash, these unshifted pairs will be put onto the front of the data structure without changing the primary keyed value. These insertions will be nullified if the hash is not multivalued.

    my @a := array-hash('a' => 1, 'b' => 2);
    @a.unshift 'a' => 3, 'b' => 4, 'c' => 5;
    @a.raku.say;
    #> array-hash((Pair), (Pair), "c" => 5, "a" => 1, "b" => 2);

    my @m := multi-hash('a' => 1, 'b' => 2);
    @m.push: 'a' => 3, 'b' => 4, 'c' => 5;
    @m.raku.say;
    #> multi-hash("a" => 3, "b" => 4, "c" => 5, "a" => 1, "b" => 2);

=head2 method prepend

    method prepend(ArrayHash:D: +@values) returns ArrayHash:D

Adds teh given values onto the beginning of the ArrayHash, just like the L<unshift method#method unshift>, but it flattens the lists given as arguments.

This modifies the ArrayHash in place and returns the new value.

=head2 method splice

    multi method splice(ArrayHash:D: &offset, Int(Cool) $size? *@values) returns ArrayHash:D
    multi method splice(ArrayHash:D: Int(Cool) $offset, &size, *@values) returns ArrayHash:D
    multi method splice(ArrayHash:D: &offset, &size, *@values) returns ArrayHash:D
    multi method splice(ArrayHash:D: Int(Cool) $offset = 0, Int(Cool) $size?, *@values) returns ArrayHash:D

This is a general purpose splice method for ArrayHash. As with L<Array> splice, it is able to perform most modification operations.

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

The C<$offset> is a point in the ArrayHash to perform the work. It is not an index, but a boundary between indexes. The 0th offset is just before index 0, the 1st offset is after index 0 and before index 1, etc.

The C<$size> determines how many elements after C<$offset> will be removed. These are returned as a new ArrayHash.

The C<@values> are a list of new values to insert, which may be a list of L<Pair>s or pairs other objects to be combined into L<Pair>s. If empty, no new values are inserted. The number of elements inserted need not have any relationship to the number of items removed.

This method will fail with an L<X::OutOfRange> exception if the C<$offset> or C<$size> is out of range.

This method will fail with a L<X::Hash::Store::OddNumber> exception if an odd number of non-L<Pair> objects is passed.

=head2 method sort

    method sort(ArrayHash:D: &by = &infix:<cmp>) returns Seq:D

Returns a sequence of L<Pair>s from the ArrayHash sorted according to the given sort function, C<&by>.

=head2 method unique

    method unique(ArrayHash:D:) returns ArrayHash:D

For a multivalued hash, this returns the same hash as a non-multivalued hash. Otherwise, it returns itself.

=head2 method rotor

This is not implemented.

=head2 method pop

    method pop(ArrayHash:D:) returns Pair

Takes the last element off the ArrayHash and returns it.

=head2 method shift

    method shift(ArrayHash:D:) returns Pair

Takes the first element off the ArrayHash and returns it.

=head2 method values

    method values(
        Bool :$hash = False,
        Bool :$array = False,
    ) returns Seq:D

Returns all the values in insertion order. In hash mode, the default, the values of the hash are returned. In array mode, the pairs are returned, which may include Pair type objects for elements that have been deleted or nullified or never set. No combined hash/array mode is defined. The mode is selected by specifying the C<:hash> or C<:array> adverbs.

    my $ah = array-hash('a' => 1, 'b' => 2);
    say $ah.values;         #> (1 2)
    say $ah.values(:array); #> (a => 1 b => 2)

For a L<multi-hash#sub multi-hash>, every value will be iterated.

    my $mh = multi-hash('a' => 1, 'a' => 2);
    my $mh.values; #> (1 2)

=head2 method keys

    method keys(
        Bool :$hash = False,
        Bool :$array = False,
    ) returns Seq:D

Returns all the keys of the stored pairs in insertion order. In hash mode, the default, the values of the keys of the hash are turned. In array mode, the indexes of the array are returned.wNon combined array/hash mode is defined. The mode is selected using the C<:hash> and C<:array> adverbs.

    my $ah = array-hash('a' => 1, 'b' => 2);
    say $ah.keys;         #> (a b)
    say $ah.keys(:array); #> (0 1)

For a L<multi-hash#sub multi-hash>, every key will be iterated:

    my $mh = multi-hash('a' => 1, 'a' => 2);
    say $ah.keys; #> (a a)

=head2 method kv

    method kv(
        Bool :$array = False,
        Bool :$hash = False,
    ) returns Seq:D

This returns an alternating sequence of keys and values. The sequence is always returned in insertion order.

In hash mode, the default, the keys will be the hash key and the value will be the hash value stored according to the L<latest key matters rule#Latest Key Matters Rule>. In array mode, the keys will be the array index and the value will be the L<Pair> stored at that index. In combined hash/array mode, the result will be a triple alternation: array index, hash key, hash value. The mode is selected using the C<:hash> and C<:array> adverbs.

    my $ah = array-hash('a' => 10, 'b' => 20);
    say $ah.kv;                #> (a 10 b 20)
    say $ah.kv(:array);        #> (0 a => 10 1 b => 20)
    say $ah.kv(:array, :hash); #> (0 a 10 1 b 20)

For a L<multi-hash#sub multi-hash>, every key/value pair will be iterated:

    my $mh = multi-hash('a' => 1, 'a' => 2);
    say $mh.kv; #> a 1 a 2

=head2 method pairs

    method pairs(
        Bool :$array = False,
        Bool :$hash = False,
    ) returns Seq:D

This returns a sequence of pairs stored in the ArrayHash. In hash mode, the default, only the defined hash key/value pairs are returned. In array mode, the array key/value pairs are returned. The keys will be the array indexes and the vvalues will be the hash key/value pair stored at each index.

    my $ah = array-hash('a' => 10, 'b' => 20);
    say $ah.pairs;        #> (a => 10 b => 20)
    say $ah.pairs(:array) #> (0 => a => 10 1 => b => 20)

=head2 method invert

    method invert() returns List:D

Not implemented.

=head2 method antipairs

    method antipairs() returns List:D

Not implemented.

=head2 method permutations

Not implemented.

=head2 method raku

    multi method raku(ArrayHash:D:) returns Str:D

Returns the Raku code that could be used to recreate this list.

=head2 method gist

    multi method gist(ArrayHash:D:) returns Str:D

Returns the Raku code that could be used to recreate this list, up to the 100th element.

=head2 method fmt

    method fmt($format = "%s\t%s", $sep = "\n") returns Str:D

Prints the contents of the ArrayHash using the given format and separator.

=head2 method reverse

    method reverse(ArrayHash:D:) returns ArrayHash:D

Returns the ArrayHash, but with pairs inserted in reverse order.

=head2 method rotate

    method rotate(ArrayHash:D: Int $n = 1) returns ArrayHash:D

Returns the ArrayHash, but with the pairs inserted rotated by C<$n> elements.

=head2 method elems

    method elems(ArrayHash:D:) returns Int:D

Returns the number of elements stored in the ArrayHash.

=head2 method end

    method end(ArrayHash:D:) returns Int:D

Returns the index of the last element stored in the ArrayHash.

=head2 method flat

    method flat(ArrayHash:D:) returns Seq:D

Returns a sequence of the Pairs stored in the ArrayHash. As the items stored are always L<Pair>s, this will always be functionally equivalent to the L<pairs method#method pairs>.

=head2 method pick

    multi method pick(ArrayHash:D:) returns Pair
    multi method pick(ArrayHash:D: Whatever) returns Seq:D
    multi method pick(ArrayHash:D: $count) returns Seq:D

When called with no arguments, returns a random L<Pair> stored in the ArrayHash. It will return Nil if the ArrayHash is empty.

When called with arguments, it will return a sequence of 0 or more unique items stored in the ArrayHash in random order. If L<Whatever> is passed, all Pairs will be reutrned from the sequence in random order.

=head2 method roll

    multi method roll(ArrayHash:D:) returns Pair
    multi method roll(ArrayHash:D: $count) returns Seq:D

When called with no arguemnts, returns a random L<Pair> stored in the ArrayHash. It will return Nil if the ArrayHash is empty.

When called with a numeric C<$count>, it will return C<$count> Pairs which are pulled random from the elements stored in the ArrayHash. The items pulled are not guaranteed to be unique.

=head2 method reduce

    method reduce(ArrayHash:D: &with)

Performs inductive iteration over the L<Pair>s stored in the ArrayHash.

For an empty ArrayHash, the given code will be called once with no arguments and the return value of that code is returned by the reduce method.

For a single item ArrayHash, the given code will be called once with a single argument, the single item stored, and the return value of that code is returned by the reduce method.

For a two item ArrayHash, the given code will be called once with two arguments, the first and second items stored, and the return value of that code is returned by the reduce method.

For a three or more item ArrayHash, the given code will be called two or more times. The first call will receive the first two elements of the ArrayHash as arguments. All subsequent calls will receive the return of the previous call as the first argument and the next ArrayHash element as the second argument. The final return value of the C<&with> code will be returned from the reduce method.

=head2 method produce

    method produce(ArrayHash:D: &with) returns Seq:D

This method operates in precisely the same manner as the L<reduce method#method reduce>, but instead of only returning the result from the final call to C<&with>, it returns a sequence that iterates through every value returned by calls to C<&with>.

=head2 method combinations

    multi method combinations(ArrayHash:D: Int() $of) returns Seq:D
    multi method combinations(ArrayHash:D: Iterable:D $of = 0..*) returns Seq:D

This method returns a seqeuence of the requested combinations of Pairs stored in the ArrayHash.

=head2 method join

    method join(ArrayHash:D: $sep = '') returns Str

Concatenates the L<Pair>s stored in the ArrayHash into a string using the given separator, C<$sep>.

=head2 method map

    method map(ArrayHash:D: &block) returns Seq:D

Returns a sequence where the result of the operation of C<&block> being applied to each L<Pair> in the ArrayHash is returned.

=head2 method grep

    method grep(ArrayHash:D: Mu $matcher, :$k, :$v, :$kv, :$p) returns Seq:D

Returns a sequence containing only the values in the ArrayHash that match the given C<$matcher>. By default, the result will be the L<Pair>s matched, but by supplying an adverb, you can modify which type of information is returned:

=item C<:k> causes only the keys to be returned.

=item C<:v> causes only the values to be returned.

=item C<:kv> causes the keys and values to be returned in an alternating sequence.

=item C<:p> causes the pairs to be returned (the default).

=head2 method first

    method first(ArrayHash:D: Mu $matcher?, :$k, :$v, :$kv, :$p, :$end)

Returns the first L<Pair> from the ArrayHash that matches the given matcher, C<$matcher> (or just the first element if no matcher is provided). The return value can be modified by using the C<:k>, C<:v>, C<:kv>, and C<:p> adverbs. See the L<grep method#method grep> for details. Instead of matching from the front of the list, it can match from the end if the C<:end> adverb is given.

=head2 method head

    method head(ArrayHash:D:) returns Pair
    method head(ArrayHash:D: $n) returns Seq:D
    method head(ArrayHash:D: &c) returns Seq:D

Returns the L<Pair>s from the front of the ArrayHash. With no arguments, it returns the first L<Pair> or C<Nil> if the ArrayHash is empty.

If a number is given, then a sequence of that many items from the front of the ArrayHash is returned.

If a L<WhateverCode> range is given, e.g., C<*-3>, then all the items from front of the list until that L<WhateverCode> range starts from the back is returned.

=head2 method tail

    method tail(ArrayHash:D:) returns Pair
    method tail(ArrayHash:D: $n) returns Seq:D
    method tail(ArrayHash:D: &c) returns Seq:D

Returns the L<Pair>s from the back of the ArrayHash. With no arguments, it returns the last L<Pair> or C<Nil> if the ArrayHash is empty.

If a number is given, then a sequence of that many items from the back of the ArrayHash is returned.

If a L<WhateverCode> range is given, e.g., C<*-3>, then all the items from back of the list until that L<WhateverCode> range starts from the front is returned.


=head2 method Array

    method Array(ArrayHash:D:) returns Array:D

Returns an L<Array> object containing the pairs in the ArrayHash.

=head2 method Hash

    method Hash(ArrayHash:D:) returns Hash:D

Returns a L<Hash> object containing the pairs of the ArrayHash. If this is a multi-hash, any keys with multiple values will be collapsed according to the L<Last Pair Matters Rule#Last Pair Matters Rule>.

=head2 method Bool

    method Bool(ArrayHash:D:) returns Bool:D

Returns C<True> if there are one or more items stored in the object. Returns C<False> if the ArrayHash is empty.

=head2 method Int

    method Int(ArrayHash:D:) returns Int:D

Returns the number of elements stored in the ArrayHash.

=head2 method Numeric

    method Numeric(ArrayHash:D:) returns Numeric:D

Returns the number of elements stored in the ArrayHash.

=head2 method Str

    method Str(ArrayHash:D:) returns Str:D

Returns a string representation of the ArrayHash. This will include a string representation of all the L<Pairs> stored with a space between them.

=head2 method Capture

    method Capture(ArrayHash:D:) returns Capture:D

Returns a L<Capture> which will have the positional arguments set to the values of the elements of this ArrayHash.

=head2 method Supply

    method Supply(ArrayHash:D:) returns Supply:D

Returns a L<Supply>, which emits the Pair elements of the ArrayHash in order.

=head2 sub array-hash

    sub array-hash(*@a, *%h) returns ArrayHash:D where { !*.multivalued }

Constructs a new ArrayHash with multivalued being false, containing the given initial pairs in the given order (or whichever order Raku picks arbitrarily if passed as L<Pair>s.

=head2 sub multi-hash

    sub multi-hash(*@a, *%h) returns ArrayHash:D where { *.multivalued }

Constructs a new multivalued ArrayHash containing the given initial pairs in the given order. (Again, if you use L<Pair>s to do the initial insertion, the order will be randomized, but stable upon insertion.)

=end pod

