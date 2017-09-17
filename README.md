# Fa

This gem provides bindings to [libfa](http://augeas.net/libfa/index.html),
a library for doing algebra on [regular expressions](#syntax). If you've
ever asked yourself questions like "Are these two regular expressions
matching the same set of strings ?" or wanted to determine a regular
expression that matches all strings that match one regular expression, but
not a second one, this is the library that can answer these questions for
you.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fa'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fa

For things to work out, you will also have to have `libfa` installed; the
library is distributed as part of [augeas](http://augeas.net/). On Red
Hat-derived distros like Fedora, CentOS, or RHEL, you will need to `yum
install augeas-libs`, on Debian-derived distros, run `apt-get install
libaugeas0`.

## Usage

To perform computations on regular expressions, `libfa` needs to first
convert your regular expression into a finite automaton. This is done by
compiling your regular expression:

```ruby
    fa1 = Fa.compile("(a|b)")  # can also be written as Fa["(a|b)"]
    fa2 = fa1.plus
```

Notice that the regular expression needs to be given as a
string. Unfortunately, Ruby regular expressions allow constructs that go
beyond the mathematical notion of a regular expression and can therefore
not be used to do the kinds of computation that `libfa` performs. The
regular expressions that `libfa` deals in must be written using a (subset
of) the notation for
[extended POSIX regular expressions](https://en.wikibooks.org/wiki/Regular_Expressions/POSIX-Extended_Regular_Expressions). The
biggest difference between POSIX ERE and the syntax that `libfa`
understands is that `libfa` does not allow backreferences, does not support
anchors like `^` and `$`, and does not support named character classes like
`[[:space:]]`.

You can always turn a finite automaton back into a regular expression using
`Fa#to_s`:

```ruby

    puts fa1
    # "b|a"
    puts fa1.minimize
    # "[ab]"
    puts fa1.union(fa2).minimize
    # "[ab][ab]*"
    puts fa1.concat(fa2).minimize
    # "[ab][ab][ab]*"
    puts fa2.intersect(fa1).minimize
    # "b|a"
    puts fa2.intersect(Fa["a*"]).minimize
    # "aa*"
    puts fa1.intersect(Fa["a*"]).minimize
    # "a"
    puts Fa["a+"].minus(Fa["a{2,}"])
    # "a"
```

You can also compare finite automata, and therefore learn things on how
they behave on _all_ strings, for example if they match the same exact set
of strings, or if one matches strictly more strings than another:

```ruby
    fa = Fa["[a-z]"].intersect(Fa["a*"])
    puts Fa["a"].equals(fa)
    # true
    fa = Fa["a"].union(Fa["b"]).star.concat(Fa["c"].plus)
    puts Fa["(a|b)*c+"].equals(fa)
    # true
    puts Fa["[ab]*"].contains(Fa["a*"])
    # true
    puts Fa["a+"].minus(Fa["a*"]).empty?
    # true
```

### Syntax

The regular expressions that `libfa` understand are a subset of the POSIX
extended regular expression syntax. If you are a regular expression
aficionado, you should note that `libfa` does not support some popular
syntax extensions. Most importantly, it does not support backreferences,
anchors such as `^` and `$`, and named character classes such as
`[[:upper:]]`. The first two are not supported since they take the notation
out of the realm of finite automata and actual regular expressions. Named
character classes are not implemented because there's a lot of work to
support them, even though there is no objection from theory to them.

The character set that `libfa` operates on is simple 8 bit ASCII. In other
words, to `libfa`, a character is a byte, and it does not support larger
character sets such as UTF-8.

The following characters have special meaning for `libfa`. The symbols `R`,
`S`, `T`, etc. in the list below can be regular expressions themselves. The
list is ordered by increasing precendence of the operators.

* `R|S`: matches anything that matches either `R` or `S`
* `R*`: matches any number of `R`, including none
* `R+`: matches any number of `R`, but at least one
* `R?`: matches no or one occurence of `R`
* `R{n,m}`: matches at least `n` but no more than `m` occurences of
  `R`. `n` must be nonnegative. If `m` is missing or equals `-1`, matches
  an unlimited number of `R`.
* `(R)`: the parentheses are solely there for grouping, and this expression
  matches the same strings as `R` alone
* `[C]`: matches the characters in the character set `C`; see below for the
  syntax of character sets
* `.`: matches any single character except for newline
* `\c`: the literal character `c`, even if it would otherwise have special
  meaning; the expression `\(` matches an opening parenthesis.

Character classes `[C]` use the following notation:

* `[^C]`: matches all characters not in `[C]`. `[^a-zA-Z]` matches
  everything that is not a letter.
* `[a-z]`: matches all characters between `a` and `z`, inclusive. Multiple
  ranges can be specified in the same character set. `[a-zA-Z0-9]` is a
  perfectly valid character set.
* if a character set should include `]`, it must be listed as the first
  character. `[][]` matches the opening and closing bracket.
* if a character set should include `-`, it must be listed as the last
  character. `[-]` matches solely a dash.
* no characters in character sets are special, and there is no backslash
  escaping of characters in character classes. `[.]` matches a literal dot.

The regular expression syntax has no notation for control characters: when
`libfa` sees `\n` in a string you are compiling, it will match that against
the character `n`, not a newline. That's not a problem as the strings you
write in Ruby code go through Ruby's backslash interpretation first. When
you write `Fa.compile("[\n]")`, `libfa` never sees the backslash as Ruby
replaces `\n` with a newline character before that string ever makes it to
`libfa`. That has the funny consequence that if you want to use a literal
backslash in your regular expression, your input string must have _four_
backslashes in it: when you write `Fa.compile("\\\\")`, Ruby first turns
that into a string with two backslashes, which `libfa` then interprets as a
single
backslash. \[_If you are reading this in YARD documentation and only saw two backslashes in the `Fa.compile`, it's because YARD reduced them from the markdown source. Github does not, and so this example will always be wrong in one of them._\]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will create a
git tag for the version, push git commits and tags, and push the `.gem`
file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/lutter/ruby-fa.
