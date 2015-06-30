unit class ArrayHash does Associative does Positional;

use v6;

use KnottyPair ();

# Until :EXPORT works ...
our sub infix:«=x>» ($key, $value) is export {
    KnottyPair.new(:$key, :$value);
}

our sub infix:«=X>» ($key, $value is rw) is export {
    my $pair = KnottyPair.new(:$key, value => Any);
    $pair.bind-value($value);
    $pair;
}

=NAME ArrayHash - a data structure that is both Array and Hash

=begin SYNOPSIS

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

=end SYNOPSIS

=begin DESCRIPTION

B<Experimental:> The API here is experimental. Some important aspects of the API may change without warning.

You can think of this as a L<Hash> that always iterates in insertion order or you can think of this as an L<Array> of L<Pair>s with fast lookups by key. Both are correct, though it really is more hashish than arrayish because of the Pairs, which is why it's an ArrayHash and not a HashArray. 

This class uses L<KnottyPair> internally, rather than plain old Pairs, but you can usually use either when interacting with objects of this class.

An ArrayHash is both Associative and Positional. This means you can use either a C<@> sigil or a C<%> sigil safely. However, there is some amount of conflicting tension between a L<Positional> and L<Assocative> data structure. An Associative object in Perl requires unique keys and has no set order. A Positional, on the othe rhand, is a set order, but no inherent uniqueness invariant. The primary way this tension is resolved depends on whether the operations you are performing are hashish or arrayish.

For example, consider this C<push> operation:

    my @a := array-hash('a' =x> 1, 'b' =x> 2);
    @a.push: 'a' =x> 3, b => 4;
    @a.perl.say;
    #> array-hash(KnottyPair, "b" =x> 4, "a" =x> 3);

Here, the C<push> is definitely an arrayish operation, but it is given both an arrayish argument, C<<'a' =x> 3>>, and a hashish argument C<<b => 4>>. Therefore, the L<KnottyPair> keyed with C<"a"> is pushed onto the end of the ArrayHash and the earlier value is nullified. The L<Pair> keyed with C<"b"> performs a more hash-like operation and replaces the value on the existing pair.

Now, compare this to a similar C<unshit> operation:

    my @a := array-hash('a' =x> 1, 'b' =x> 2);
    @a.unshift: 'a' =x> 3, b => 4;
    @a.perl.say;
    #> array-hash(KnottyPair, 'a' =x> 1, 'b' =x> 2);

What happened? Why didn't the values changed and where did this extra L<KnottyPair> come from? Again, C<unshift> is arrayish and we have an arrayish and a hashish argument, but this time we demonstrate another normal principle of Perl hashes that is enforced, which is, when dealing with a list of L<Pair>s, the latest Pair is the one that bequeaths its value to the hash. That is,

    my %h = a => 1, a => 2;
    say "a = %h<a>";
    #> a = 2

Since an L<ArrayHash> maintains its order, this rule always applies. A value added near the end will win over a value at the beginning. Adding a value near the beginning will lose to a value nearer the end.

So, returning to the C<unshift> example above, the arrayish value with key C<"a"> gets unshifted to the front of the array, but immediately nullified because of the later value. The hashish value with key C<"b"> sees an existing value for the same key and the existing value wins since it would come after it. 

The same rule holds for all operations: If the key already exists, but before the position the value is being added, the new value wins. If the key already exists, but after the position we are inserting, the old value wins.

For a regular ArrayHash, the losing value will either be replaced, if the operation is hashish, or will be nullified, if the operation is arrayish. 

This might not always be the desired behavior so this module also provides the multivalued ArrayHash, or multi-hash:

    my @a := multi-hash('a' =x> 1, 'b' =x> 2);
    @a.push: 'a' =x> 3, b => 4;
    @a.perl.say;
    #> multi-hash('a' =x> 1, "b" =x> 4, "a" =x> 3);

The operations all work the same, but array values are not nullified and it is find for there to be multiple values in the array. This is the same class, ArrayHash, but the L<has $.multivalued> property is set to true.

[Conjecture: Consider adding a C<has $.collapse> attribute or some such to govern whether a replaced value in a C<$.multivalued> array hash is replaced with a type object or spiced out. Or perhaps change the C<$.multivalued> into an enum of operational modes.]

[Conjecture: In the future, a parameterizable version of this class could be created with some sort of general keyable object trait rather than KnottyPair.]

=end DESCRIPTION

has %!hash;
has KnottyPair @!array handles <
    elems Bool Int end Numeric Str
    flat list lol flattens Capture Parcel Supply
    pick roll reduce combinations
>;

=begin pod

=head1 Attributes

=head2 has $.multivalued

    has $.multivalued = False;

This determines whether the ArrayHash is a regular array-hash or a multi-hash. Usually, you will use the L<sub array-hash> or L<sub multi-hash> constructors rather than setting this directly.

=end pod

has Bool $.multivalued = False;

# TODO make this a macro...
sub want($key) {
    & = { .defined && .key eqv $key }
}

=begin pod

=head2 method new

    method new(Bool :multivalued = False, *@a, *%h) returns ArrayHash:D

Constructs a new ArrayHash. This is not the preferred method of construction. You should use L<sub array-hash> or L<sub multi-hash> instead.

=end pod

method new(Bool :$multivalued = False, *@a, *%h)  {
    my $self = self.bless(:$multivalued);
    $self.push: |@a, |%h;
    $self
}

submethod BUILD(:$!multivalued) { self }

=begin pod

=head2 method of

    method of() returns Mu:U

Returns what type of values are stored. This always returns a L<KnottyPair> type object.

=end pod

method of() {
    self.Positional::of();
}

method !clear-before($pos, $key) {
    my @pos = @!array[0 .. $pos - 1].grep-index(want($key));

    # Rakudo Bug [perl #125457]
    if @pos {
        for @pos { @!array[$_] = KnottyPair }
    }

    @!array[@pos] :delete;
}

method !found-after($pos, $key) returns Bool {
    @!array[$pos + 1 .. @!array.end].first-index(want($key)) ~~ Int
}

=begin pod

=head2 method postcircumfix:<{ }>

    method postcircumfix:<( )>(ArrayHash:D: $key) returns Mu

This provides the usual value lookup by key. You can use this to retrieve a value, assign a value, or bind a value. You may also combine this with the hash adverbs C<:delete> and C<:exists>.

=end pod

method AT-KEY(ArrayHash:D: $key) { 
    %!hash{$key} 
}

=begin pod

=head2 method postcircumfix:<[ ]>

    method postcircumfix:<[ ]>(ArrayHash:D: Int:D $pos) returns KnottyPair

This returns the value lookup by index. You can use this to retrieve the pair at the given index or assign a new pair or even bind a pair. It may be combined with the array adverts C<:delete> and C<:exists> as well.

=end pod

method AT-POS(ArrayHash:D: $pos) returns KnottyPair {
    @!array[$pos];
}

method ASSIGN-KEY(ArrayHash:D: $key, $value is copy) { 
    POST { %!hash{$key} =:= @!array[ @!array.last-index(want($key)) ].value }

    if %!hash{$key} :exists {
        %!hash{$key} = $value;
    }
    else {
        @!array.push: $key =X> $value;
        %!hash{$key} := $value;
    }
}

method ASSIGN-POS(ArrayHash:D: $pos, KnottyPair:D $pair is copy) {
    PRE  { $!multivalued || @!array.grep(want($pair.key)).elems <= 1 }
    POST { $!multivalued || @!array.grep(want($pair.key)).elems <= 1 }
    POST { %!hash{$pair.key} =:= @!array[ @!array.last-index(want($pair.key)) ].value }

    if !$!multivalued && (%!hash{ $pair.key } :exists) {
        self!clear-before($pos, $pair.key);
    }

    if @!array[$pos] :exists && @!array[$pos].defined {
        %!hash{ @!array[$pos].key } :delete;
    }

    my $orig = @!array[ $pos ];

    if self!found-after($pos, $pair.key) {
        if $!multivalued {
            @!array[ $pos ] = $pair;
        }
        else {
            @!array[ $pos ] = KnottyPair;
        }
    }
    else {
        %!hash{ $pair.key } := $pair.value;
        @!array[ $pos ]      = $pair;
    }

    if $!multivalued && $orig.defined {
        my $npos = @!array.last-index(want($orig.key));
        if $npos ~~ Int {
            %!hash{ $orig.key } := @!array[$npos].value;
        }
    }

    $pair;
}

method BIND-KEY(ArrayHash:D: $key, $value is rw) is rw { 
    POST { %!hash{$key} =:= @!array.reverse.first(want($key)).value }

    if %!hash{$key} :exists {
        %!hash{$key} := $value;
        my $pos = @!array.last-index(want($key));
        @!array[$pos].bind-value($value);
    }
    else {
        %!hash{$key} := $value;
        @!array.push: $key =X> $value;
    }
}

method BIND-POS(ArrayHash:D: $pos, KnottyPair:D $pair is rw) {
    PRE  { $!multivalued || @!array.grep(want($pair.key)).elems <= 1 }
    POST { $!multivalued || @!array.grep(want($pair.key)).elems <= 1 }
    POST { %!hash{$pair.key} =:= @!array.reverse.first(want($pair.key)).value }

    if !$!multivalued && (%!hash{ $pair.key } :exists) {
        self!clear-before($pos, $pair.key);
    }

    if @!array[$pos] :exists && @!array[$pos].defined {
        %!hash{ @!array[$pos].key } :delete;
    }

    if self!found-after($pos, $pair.key) {
        if $!multivalued {
            @!array[ $pos ] := $pair;
        }
        else {
            @!array[ $pos ] = KnottyPair;
        }
    }
    else {
        %!hash{ $pair.key } := $pair.value;
        @!array[ $pos ]     := $pair;
    }
}

method EXISTS-KEY(ArrayHash:D: $key) {
    %!hash{$key} :exists;
}

method EXISTS-POS(ArrayHash:D: $pos) {
    @!array[$pos] :exists;
}

method DELETE-KEY(ArrayHash:D: $key) {
    POST { %!hash{$key} :!exists }
    POST { @!array.first-index(want($key)) ~~ Nil }

    if %!hash{$key} :exists {
        for @!array.grep-index(want($key)).reverse -> $pos {
            @!array.splice($pos, 1);
        }
    }

    %!hash{$key} :delete;
}

method DELETE-POS(ArrayHash:D: $pos) returns KnottyPair {
    my KnottyPair $pair;

    POST { @!array[$pos] ~~ KnottyPair:U }
    POST { 
        $pair.defined && !$!multivalued ??
            @!array.first-index(want($pair.key)) ~~ Nil
        !! True
    }
    POST {
        $pair.defined && $!multivalued ??
            (@!array.first-index(want($pair.key)) ~~ Int
                and %!hash{ $pair.key } :exists)
         ^^ (@!array.first-index(want($pair.key)) ~~ Nil
                and %!hash{ $pair.key } :!exists)
        !! True
    }

    if $pair = @!array[ $pos ] :delete {
        %!hash{ $pair.key } :delete;
    }

    $pair;
}

method push(ArrayHash:D: *@values, *%values) returns ArrayHash:D {
    for @values    -> $p     { self.ASSIGN-POS(@!array.elems, $p) }
    for %values.kv -> $k, $v { self.ASSIGN-KEY($k, $v) }
    self
}

method unshift(ArrayHash:D: *@values, *%values) returns ArrayHash:D {
    for @values.kv -> $i, $p {
        if !$!multivalued and %!hash{ $p.key } :exists {
            @!array.unshift: KnottyPair;
        }
        else {
            @!array.unshift: $p;
            %!hash{ $p.key } := $p.value
                unless self!found-after($i, $p.key);
        }
    }

    for %values.kv -> $k, $v {
        if %!hash{ $k } :!exists {
            @!array.unshift: $k =X> $v;
            %!hash{ $k } := $v;
        }
        elsif $!multivalued {
            @!array.unshift: $k =X> $v;
        }
    }

    self
}

multi method splice(&offset, Int(Cool) $size?, *@values, *%values) returns ArrayHash:D {
    callsame(offset(self.elems), $size, |@values, |%values)
}

multi method splice(Int(Cool) $offset, &size, *@values, *%values) returns ArrayHash:D {
    callsame($offset, size(self.elems - $offset), |@values, |%values)
}

multi method splice(&offset, &size, *@values, *%values) returns ArrayHash:D {
    my $o = offset(self.elems);
    callsame($o, size(self.elems - $o), |@values, |%values)
}

multi method splice(Int(Cool) $offset = 0, Int(Cool) $size?, *@values, *%values) returns ArrayHash:D {
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
    for @values, %values.pairs -> $pair {
        my $p = do given $pair {
            when KnottyPair:D { $pair }
            when .defined { $pair.key =x> $pair.value }
            default { KnottyPair }
        };

        my $pos = do if !$!multivalued && $p.defined {
            @!array[$offset + $size .. @!array.end].first-index(want($p.key));
        }
        else { Nil }

        @repl.push($pos ~~ Int ?? KnottyPair !! $p);
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

method sort(ArrayHash:D: $by = &infix:<cmp>) returns ArrayHash:D {
    die "not yet implemented";    
}

# Duh... we are always already unique... though, this not completely implemented
# yet.
method unique(ArrayHash:D:) returns ArrayHash:D { self }
method squish(ArrayHash:D:) returns ArrayHash:D { self }

method rotor(ArrayHash:D:) { 
    die "not yet implemented";
}

method pop(ArrayHash:D:) returns KnottyPair {
    self.DELETE-POS(@!array.end)
}

method shift(ArrayHash:D) returns KnottyPair {
    my $head;
    $head = @!array.shift
        andthen %!hash{ $head.key } :delete;
    return $head;
}

method values() returns List:D { @!array».value.list }
method keys() returns List:D { @!array».key.list }
method indexes() returns List:D { @!array.keys }
method kv() returns List:D { @!array».kv.list }
method ip() returns List:D { @!array.kv }
method ikv() returns List:D { 
    @!array.kv.flatmap({ .defined && KnottyPair ?? .kv !! $_ })
}
method pairs() returns List:D { @!array }

method invert() returns List:D {
    die 'not yet implemented'
}

method antipairs() returns List:D {
    die 'not yet implemented'
}

method permutations() {
    die 'not yet implmeneted'
}

multi method perl() returns Str:D {
    my $type = $!multivalued ?? 'multi-hash' !! 'array-hash';
    $type ~ '(' ~ @!array.map({ .defined ?? .perl !! 'KnottyPair' }).join(', ') ~ ')'
}

multi method gist() returns Str:D {
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

method rotate(ArrayHash:D: Int $n) {
    ArrayHash.new(;$!multivalued).push(|@!array.rotate($n))
}

# my role TypedArrayHash[::TValue] does Associative[TValue] does Positional[Pair] {
# 
# }
# 
# my role TypedArrayHash[::TValue, ::TKey] does Associative[TValue] does Positional[Pair] {
# }
# 
# # Taken from Hash.pm
# method ^parameterize(Mu:U \hash, Mu:U \t, |c) {
#     if c.elems == 0 {
#         my $what := hash.^mixin(TypedArrayHash[t]);
#         # needs to be done in COMPOSE phaser when that works
#         $what.^set_name("{hash.^name}[{t.^name}]");
#         $what;
#     }
#     elsif c.elems == 1 {
#         my $what := hash.^mixin(TypedArrayHash[t, c[0].WHAT]);
#         # needs to be done in COMPOSE phaser when that works
#         $what.^set_name("{hash.^name}[{t.^name},{c[0].^name}]");
#         $what;
#     }
#     else {
#         die "Can only type-constrain ArrayHash with [ValueType] or [ValueType,KeyType]";
#     }
# }

our sub array-hash(*@a, *%h) is export { ArrayHash.new(|@a, |%h) }
our sub multi-hash(*@a, *%h) is export { ArrayHash.new(:multivalued).push(|@a, |%h) }
