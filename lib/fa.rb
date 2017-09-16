require "fa/version"
require "fa/ffi"

module Fa
  class Error < StandardError; end

  class OutOfMemoryError < Error; end

  class Automaton < ::FFI::AutoPointer
    attr_reader :faptr

    def initialize(faptr)
      @faptr = faptr
    end

    def minimize
      r = FFI::minimize(faptr)
      raise Error if r < 0
      self
    end

    def concat(other)
      from_ptr( FFI::concat(faptr, other.faptr) )
    end

    def union(other)
      from_ptr( FFI::union(faptr, other.faptr) )
    end

    def iter(min, max)
      from_ptr( FFI::iter(faptr, min, max) )
    end

    def star
      iter(0, -1)
    end

    def plus
      iter(1, -1)
    end

    def maybe
      iter(0, 1)
    end

    def intersect(other)
      from_ptr( FFI::intersect(faptr, other.faptr) )
    end

    def minus(other)
      from_ptr( FFI::minus(faptr, other.faptr) )
    end

    def complement
      from_ptr( FFI::complement(faptr) )
    end

    def equals(other)
      r = FFI::equals(faptr, other.faptr)
      raise Error if r < 0
      return r == 1
    end

    def contains(other)
      # The C function works like fa1 <= fa2, and not how the
      # Ruby nomenclature would suggest it, so swap the arguments
      r = FFI::contains(other.faptr, faptr)
      raise Error if r < 0
      return r == 1
    end

    def is_basic(basic)
      # FFI::is_basic checks if the automaton is structurally the same as
      # +basic+; we just want to check here if they accept the same
      # language. If is_basic fails, we therefore check for equality
      r = FFI::is_basic(faptr, basic)
      return true if r == 1
      return equals(Fa::make_basic(basic))
    end

    def empty?; is_basic(:empty); end
    def epsilon?; is_basic(:epsilon); end
    def total?; is_basic(:total); end

    def as_regexp
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
      raise OutOfMemoryError if ptr.nil?
      Automaton.new(ptr)
    end
  end

  def self.compile(rx)
    faptr = ::FFI::MemoryPointer.new :pointer
    r = FFI::compile(rx, rx.size, faptr)
    raise Error if r < 0
    Automaton.new(faptr.get_pointer(0))
  end

  def self.make_basic(kind)
    faptr = FFI::make_basic(kind)
    raise OutOfMemoryError if faptr.nil?
    Automaton.new(faptr)
  end
end
