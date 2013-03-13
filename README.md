# c64-ruby

## Summary

Ruby library and tools for Commodore 64 development

## C64::Color

This module is responsible for providing conversion from
24-bit RGB values, 32-bit RGBA values and symbolic names
to C64 color indexes.

A color index is a number in the [0-15] range, representing
one of the 16 colors in the C64 VIC-II chip's palette.

### Constants

```ruby
include C64::Color::Names

RED          # => 2
LIGHT_GREEN  # => 13
```

### Methods

```ruby
# Index from symbol
C64::Color.from_symbol(:blue)   # => 6
C64::Color.from_symbol(:PURPLE) # => 4

# Index from 32-bit RGBA value (alpha is ignored)
C64::Color.from_rgba(0xFF000080) # => 10

# Index from 24-bit RGB value
C64::Color.from_rgba(0x00FFFF) # => 3

# Predefined palette
C64::Color.palette # => {0x000000 => 0, 0xD5D5D5 => 1, ...}
```

## Todo

* Add more documentation
* Rewrite remaining library classes (image, screen, charset, prototype)
* Release first version of gem
