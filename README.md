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

# Index from 24-bit RGB value
C64::Color.from_rgb(0x00FFFF) # => 3

# Index from 32-bit RGBA value (alpha is simply ignored)
C64::Color.from_rgba(0xFF000080) # => 10

# Predefined palette
C64::Color.palette # => {0x000000 => 0, 0xD5D5D5 => 1, ...}

# ANSI foreground color sequence resembling the given index
C64::Color.xterm256_escape(3) # => "\033[38;5;6m"

# ANSI background color sequence resembling the given index
C64::Color.xterm256_escape(7, true) # => "\033[48;5;185m"

# Output a string of colored spaces describing a hires pixel
C64::Color.xterm256_dump(4) # => "\033[48;5;5m  "

# Output a string of colored spaces describing a multicolor pixel
C64::Color.xterm256_dump(2, true) # => "\033[48;5;52m    "
```

## Todo

* Add more documentation
* Rewrite remaining library classes (image, screen, charset, prototype)
* Release first version of gem

## Licence

```
Copyright (c) 2013 Lars Haugseth

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
