require 'ffi'

module Fa::FFI
  extend FFI::Library

  ffi_lib 'fa'

  enum :basic, [ :empty, :epsilon, :total ]

  attach_function :compile, :fa_compile, [ :string, :size_t, :pointer ], :int
  attach_function :make_basic, :fa_make_basic, [ :basic ], :pointer

  attach_function :minimize, :fa_minimize, [ :pointer ], :int

  attach_function :concat, :fa_concat, [ :pointer, :pointer ], :pointer
  attach_function :union, :fa_union, [ :pointer, :pointer ], :pointer
  attach_function :intersect, :fa_intersect, [ :pointer, :pointer ], :pointer
  attach_function :complement, :fa_complement, [ :pointer ], :pointer
  attach_function :minus, :fa_minus, [ :pointer, :pointer ], :pointer
  attach_function :iter, :fa_iter, [ :pointer, :int, :int ], :pointer

  attach_function :contains, :fa_contains, [ :pointer, :pointer ], :int
  attach_function :equals, :fa_equals, [ :pointer, :pointer ], :int
  attach_function :is_basic, :fa_is_basic, [ :pointer, :basic ], :int

  attach_function :as_regexp, :fa_as_regexp,
                  [ :pointer, :pointer, :pointer ], :int
  attach_function :free, :fa_free, [ :pointer ], :void

  # Missing bindings:
  #   fa_dot
  #   fa_overlap
  #   fa_example
  #   fa_ambig_example
  #   fa_as_regexp
  #   fa_restrict_alphabet
  #   fa_expand_char_ranges
  #   fa_nocase
  #   fa_is_nocase
  #   fa_expand_nocase
  #   fa_enumerate
end
