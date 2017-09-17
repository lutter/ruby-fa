require "fa/version"
require "fa/ffi"

# Namespace for the libfa bindings
module Fa
  # A generic error encountered during an fa operation
  class Error < StandardError; end

  # An operation in libfa failed because it could not allocate enough
  # memory
  class OutOfMemoryError < Error; end

  # The class representing a finite automaton. It contains a pointer to a
  # +struct fa+ from +libfa+ and provides Ruby wrappers for the various
  # +libfa+ operations.
  class Automaton < ::FFI::AutoPointer
    attr_reader :faptr

    def initialize(faptr)
      @faptr = faptr
    end

    # Minimizes this automaton in place. Uses either Hopcroft's or
    # Brzozowski's algorithm. Due to a stupid design mistake in +libfa+,
    # the algorithm is selected through a global variable. It defaults to
    # Hopcroft's algorithm though.
    #
    # @return [Fa::Automaton] this automaton
    def minimize
      r = FFI::minimize(faptr)
      raise Error if r < 0
      self
    end

    # Concatenates +self+ with +other+, corresponding to +SO+. Neither
    # +self+ nor +other+ will be modified.
    #
    # @param [Fa::Automaton] other
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the concatenation of +self+ and +other+
    def concat(other)
      from_ptr( FFI::concat(faptr, other.faptr) )
    end

    # Produces the union of +self+ with +other+, corresponding to
    # +S|O+. Neither +self+ nor +other+ will be modified.
    #
    # @param [Fa::Automaton] other
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the union of +self+ and +other+
    def union(other)
      from_ptr( FFI::union(faptr, other.faptr) )
    end

    # Produces an iteration of +self+, corresponding to
    # +S{min,max}+. +self+ will not be modified.
    #
    # @param [Int] min the minimum number of matches
    # @param [Int] max the maximum number of matches, use -1 for an
    #              unlimited number of matches
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the iterated automaton
    def iter(min, max)
      from_ptr( FFI::iter(faptr, min, max) )
    end

    # Produces an iteration of any number of +self+, corresponding to
    # +S*+. +self+ will not be modified.
    #
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the iterated automaton
    def star
      iter(0, -1)
    end

    # Produces an iteration of at least one +self+, corresponding to
    # +S\++. +self+ will not be modified.
    #
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the iterated automaton
    def plus
      iter(1, -1)
    end

    # Produces an iteration of zero or one +self+, corresponding to
    # +S?+. +self+ will not be modified.
    #
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the iterated automaton
    def maybe
      iter(0, 1)
    end

    # Produces the intersection of +self+ and +other+. Neither +self+ nor
    # +other+ will be modified. The resulting automaton will match all
    # strings that simultaneously match +self+ and +other+,
    #
    # @param [Fa::Automaton] other
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the iterated automaton
    def intersect(other)
      from_ptr( FFI::intersect(faptr, other.faptr) )
    end

    # Produces the difference of +self+ and +other+. Neither +self+ nor
    # +other+ will be modified. The resulting automaton will match all
    # strings that match +self+ but not +other+,
    #
    # @param [Fa::Automaton] other
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the iterated automaton
    def minus(other)
      from_ptr( FFI::minus(faptr, other.faptr) )
    end

    # Produces the complement of +self+. +self+ will not be modified. The
    # resulting automaton will match all strings that do _not_ match
    # +self+.
    #
    # @raise OutOfMemoryError if +libfa+ fails to allocate memory
    # @return [Fa::Automaton] the iterated automaton
    def complement
      from_ptr( FFI::complement(faptr) )
    end

    # Returns whether +self+ and +other+ match the same set of strings
    #
    # @param [Fa::Automaton] other
    # @return [Boolean]
    def equals(other)
      r = FFI::equals(faptr, other.faptr)
      raise Error if r < 0
      return r == 1
    end

    # Returns whether +self+ and +other+ match the same set of strings
    #
    # @param [Fa::Automaton] other
    # @return [Boolean]
    def ==(other); equals(other); end

    # Returns whether +self+ matches all the strings that +other+
    # matches. +self+ may match more strings than that.
    #
    # @param [Fa::Automaton] other
    # @return [Boolean]
    def contains(other)
      # The C function works like fa1 <= fa2, and not how the
      # Ruby nomenclature would suggest it, so swap the arguments
      r = FFI::contains(other.faptr, faptr)
      raise Error if r < 0
      return r == 1
    end

    # Returns whether +other+ matches all the strings that +self+
    # matches. +other+ may match more strings than that.
    #
    # @param [Fa::Automaton] other
    # @return [Boolean]
    def <=(other); other.contains(self); end

    # Returns whether +self+ is the empty, epsilon or total automaton
    #
    # @param [:empty, :epsilon, :total] kind
    # @return [Boolean]
    def is_basic(kind)
      # FFI::is_basic checks if the automaton is structurally the same as
      # +basic+; we just want to check here if they accept the same
      # language. If is_basic fails, we therefore check for equality
      r = FFI::is_basic(faptr, kind)
      return true if r == 1
      return equals(Fa::make_basic(kind))
    end

    # Returns whether +self+ is the empty automaton, i.e., matches no words
    # at all
    # @return [Boolean]
    def empty?; is_basic(:empty); end

    # Returns whether +self+ is the epsilon automaton, i.e., matches only
    # the empty string
    # @return [Boolean]
    def epsilon?; is_basic(:epsilon); end

    # Returns whether +self+ is the total automaton, i.e., matches all
    # possible words.
    # @return [Boolean]
    def total?; is_basic(:total); end

    # Return the representation of +self+ as a regular expression. Note
    # that that regular expression can look pretty complicated, even for
    # seemingly simple automata. Sometimes, minimizing the automaton before
    # turning it into a string helps; sometimes it doesn't.
    #
    # @return [String] the regular expression for +self+
    def to_s
      rx = ::FFI::MemoryPointer.new :string
      rx_len = ::FFI::MemoryPointer.new :size_t
      r = FFI::as_regexp(faptr, rx, rx_len)
      raise OutOfMemoryError if r < 0
      str_ptr = rx.read_pointer()
      return str_ptr.null? ? nil : str_ptr.read_string()
    end

    def self.release(faptr)
      FFI::free(faptr)
    end

    :private
    def from_ptr(ptr)
      raise OutOfMemoryError if ptr.null?
      Automaton.new(ptr)
    end
  end

  # Compiles +rx+ into a finite automaton
  # @param [String] rx a regular expression
  # @return [Fa::Automaton] the finite automaton
  def self.compile(rx)
    faptr = ::FFI::MemoryPointer.new :pointer
    r = FFI::compile(rx, rx.size, faptr)
    raise Error if r != 0 # REG_NOERROR is 0, at least for glibc
    Automaton.new(faptr.get_pointer(0))
  end

  # Compiles +rx+ into a finite automaton
  # @param [String] rx a regular expression
  # @return [Fa::Automaton] the finite automaton
  def self.[](rx)
    compile(rx)
  end

  # Makes a basic finite automaton, either an empty, epsilon, or total
  # finite automaton. Those match no words, only the empty word, or all
  # words.
  # @param [:empty, :epsilon, :total] kind
  # @return [Fa::Automaton] the finite automaton
  def self.make_basic(kind)
    faptr = FFI::make_basic(kind)
    raise OutOfMemoryError if faptr.null?
    Automaton.new(faptr)
  end
end
