# c64-ruby

## Summary

Ruby library and tools for Commodore 64 development

## C64::Color

A color index is a number in the [0-15] range, representing a color
in the C64 VIC-II chip's 16 color palette.

Color index from symbol (case insensitive):
```ruby
C64::Color.from_symbol(:blue) # => 6
C64::Color.from_symbol(:LIGHT_GREEN) # => 13
```

Color index from 24-bit RGB value:
```ruby
C64::Color.from_rgb(0xFF0000) # => 10
```

Color index from 32-bit RGBA value (alpha is ignored):
```ruby
C64::Color.from_rgba(0x404040FF) # => 11
```

## Todo

* Add documentation
* Rewrite remaining library classes
* Release first version of gem
