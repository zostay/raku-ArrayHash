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
has KnottyPair @!array;

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
    unless %!hash{$key} :exists {
        @!array.push: $key =X> $value;
    }

    %!hash{$key} := $value;
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

method push(ArrayHash:D: *@values, *%values) {
    for @values    -> $p     { self.ASSIGN-KEY($p.key, $p.value) }
    for %values.kv -> $k, $v { self.ASSIGN-KEY($k, $v) }
    Mu
}

method values() returns List:D { @!array».value.list }
method keys() returns List:D { @!array».key.list }
method kv() returns List:D { @!array».kv.list }
method pairs() returns List:D { @!array }

my role TypedArrayHash[::TValue] does Associative[TValue] does Positional[Pair] {

}

my role TypedArrayHash[::TValue, ::TKey] does Associative[TValue] does Positional[Pair] {
}

# Taken from Hash.pm
method ^parameterize(Mu:U \hash, Mu:U \t, |c) {
    if c.elems == 0 {
        my $what := hash.^mixin(TypedArrayHash[t]);
        # needs to be done in COMPOSE phaser when that works
        $what.^set_name("{hash.^name}[{t.^name}]");
        $what;
    }
    elsif c.elems == 1 {
        my $what := hash.^mixin(TypedArrayHash[t, c[0].WHAT]);
        # needs to be done in COMPOSE phaser when that works
        $what.^set_name("{hash.^name}[{t.^name},{c[0].^name}]");
        $what;
    }
    else {
        die "Can only type-constrain ArrayHash with [ValueType] or [ValueType,KeyType]";
    }
}

sub array-hash(*@a, *%h) is export { ArrayHash.new(|@a, |%h) }
