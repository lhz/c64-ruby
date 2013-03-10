require 'rubygame'

module R64

  class InvalidColorError < StandardError
    def initialize(color)
      super("No color with value 0x#{color.to_s(16).upcase} in palette.")
    end
  end

  module Color

    BLACK        = 0
    WHITE        = 1
    RED          = 2
    CYAN         = 3
    PURPLE       = 4
    GREEN        = 5
    BLUE         = 6
    YELLOW       = 7
    ORANGE       = 8
    BROWN        = 9
    LIGHT_RED    = 10
    DARK_GREY    = 11
    MEDIUM_GREY  = 12
    LIGHT_GREEN  = 13
    LIGHT_BLUE   = 14
    LIGHT_GREY   = 15

    def self.from_symbol(symbol)
      const_get symbol.to_s.upcase.to_sym
    end

    def self.from_rgba(value, default = nil)
      from_rgb value >> 8
    end

    def self.from_rgb(value, default = nil)
      palette[value] || default or
        raise InvalidColorError.new(value)
    end

    def self.xterm_ansi(index, bg = false)
      map = [
        0x10, 0x0f, 0x34, 0x06,
        0x05, 0x02, 0x13, 0xb9,
        0x5e, 0x3a, 0x83, 0xee,
        0xf3, 0x72, 0x3f, 0xf8,
      ]
      "\033[#{bg ? 48 : 38};5;#{map[index]}m"
    end

    def self.xterm_dump(index, double = false)
      xterm_ansi(index, true) + (double ? "    " : "  ")
    end

    def self.palette
      @palette ||= {
        0x000000 => BLACK,
        0xD5D5D5 => WHITE,
        0x72352C => RED,
        0x659FA6 => CYAN,
        0x733A91 => PURPLE,
        0x568D35 => GREEN,
        0x2E237D => BLUE,
        0xAEB75E => YELLOW,
        0x774F1E => ORANGE,
        0x4B3C00 => BROWN,
        0x9C635A => LIGHT_RED,
        0x474747 => DARK_GREY,
        0x6B6B6B => MEDIUM_GREY,
        0x8FC271 => LIGHT_GREEN,
        0x675DB6 => LIGHT_BLUE,
        0x8F8F8F => LIGHT_GREY
      }
    end

    def self.palette=(palette)
      @palette = palette
    end

    def self.palette_merge(hash)
      palette && @palette.merge!(hash)
    end

  end
end
