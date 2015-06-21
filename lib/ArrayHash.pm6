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

=begin DESCRIPTION

You can think of this as a L<Hash> that always iterates in insertion order or you can think of this as an L<Array> of L<Pair>s with fast lookups on tha values. Both are correct. Though, this class uses L<KnottyPair> internally, rather than plain old Pairs.

=end DESCRIPTION

has %!hash;
has KnottyPair @!array handles <
    elems Bool Int end Numeric Str
    flat list lol flattens Capture Parcel Supply
    pick roll reduce combinations
>;

method new(*@a, *%h) {
    my $self = self.bless;
    $self.push: |@a, |%h;
    $self
}

method of() {
    self.Positional::of();
}

method AT-KEY(ArrayHash:D: $key) { 
    %!hash{$key} 
}

method AT-POS(ArrayHash:D: $pos) returns KnottyPair {
    @!array[$pos];
}

method ASSIGN-KEY(ArrayHash:D: $key, $value is copy) { 
    if %!hash{$key} :exists {
        %!hash{$key} = $value;
    }
    else {
        @!array.push: $key =X> $value;
        %!hash{$key} := $value;
    }

    %!hash{$key} =:= @!array.first(*.key eqv $key).value
        or die "internal representation mismatch";
}

method ASSIGN-POS(ArrayHash:D: $pos, KnottyPair:D $pair is copy) {
    if @!array[$pos] :exists {
        %!hash{ @!array[$pos].key } :delete;
    }

    %!hash{ $pair.key } := $pair.value;
    @!array[ $pos ] = $pair;
}

method BIND-KEY(ArrayHash:D: $key, $value is rw) is rw { 
    if %!hash{$key} :exists {
        %!hash{$key} := $value;
        my $pos = @!array.first-index(*.key eqv $key);
        @!array[$pos].bind-value($value);
    }
    else {
        %!hash{$key} := $value;
        @!array.push: $key =X> $value;
    }
}

method BIND-POS(ArrayHash:D: $pos, KnottyPair:D $pair is rw) {
    if @!array[$pos] :exists {
        %!hash{ @!array[$pos].key } :delete;
    }

    %!hash{ $pair } := $pair.value;
    @!array[ $pos ] := $pair;
}

method EXISTS-KEY(ArrayHash:D: $key) {
    %!hash{$key} :exists;
}

method EXISTS-POS(ArrayHash:D: $pos) {
    @!array[$pos] :exists;
}

method DELETE-KEY(ArrayHash:D: $key) {
    if %!hash{$key} :exists {
        my $pos = @!array.first-index(*.key eqv $key);
        @!array.splice($pos, 1);
    }

    %!hash{$key} :delete;
}

method DELETE-POS(ArrayHash:D: $pos) returns KnottyPair {
    my KnottyPair $pair;
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
    for @values -> $p {
        if %!hash{ $p.key } :exists {
            @!array.unshift: KnottyPair;
        }
        else {
            @!array.unshift: $p;
            %!hash{ $p.key } := $p.value;
        }
    }

    for %values.kv -> $k, $v {
        if %!hash{ $k } :!exists {
            @!array.unshift: $k =X> $v;
            %!hash{ $k } := $v;
        }
    }
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
    for @values -> $p {
        my $pos = @!array[$offset + 1 .. self.end].first-index(*.key eqv $p.key);
        @repl.push($pos >= 0 ?? $p !! KnottyPair);
    }

    # Splice the array
    my @ret = @!array.splice($offset, $size, @repl);

    # Replace hash elements with new values
    for @repl -> $p {
        %!hash{ $p.key } := $p.value if $p.defined;
    }

    # Nullify earlier values that have just been replaced
    for @!array[0 .. $offset].kv -> $i, $p {
        @!array[$i] :delete 
            if @repl.grep({ .defined && .key eqv $p.key });
    }

    # Return the removed elements
    return ArrayHash.new(|@ret);
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
    'array-hash(' ~ @!array».perl.join(', ') ~ ')'
}

multi method gist() returns Str:D {
    'array-hash(' ~ do for @!array -> $elem { 
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
    ArrayHash.new(|@!array.reverse)
}

method rotate(ArrayHash:D: Int $n) {
    ArrayHash.new(|@!array.rotate($n))
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

sub array-hash(*@a, *%h) is export { ArrayHash.new(|@a, |%h) }
