module R64

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
      from_rgb value >> 8, default
    end

    def self.from_rgb(value, default = nil)
      palette[value] || default || guess_from_rgb(value)
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
        # VICE
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
        0x8F8F8F => LIGHT_GREY,
        # PEPTO
        0xffffff => WHITE,
        0x68372b => RED,
        0x70a4b2 => CYAN,
        0x6f3d86 => PURPLE,
        0x588d43 => GREEN,
        0x352879 => BLUE,
        0xb8c76f => YELLOW,
        0x6f4f25 => ORANGE,
        0x433900 => BROWN,
        0x9a6759 => LIGHT_RED,
        0x444444 => DARK_GREY,
        0x6c6c6c => MEDIUM_GREY,
        0x9ad284 => LIGHT_GREEN,
        0x6c5eb5 => LIGHT_BLUE,
        0x959595 => LIGHT_GREY,
        # PAL
        0xc1c1c1 => WHITE,
        0xc5c5c5 => WHITE,
        0x8b8b8b => LIGHT_GREY,
      }
    end

    def self.palette=(palette)
      @palette = palette
    end

    def self.palette_merge(hash)
      palette && @palette.merge!(hash)
    end

    # Guess C64 color index from given 24-bit RGB value
    def self.guess_from_rgb(value)
      h, s, v = rgb_to_hsv(value)
      if s < 0.2
        case v * 100
        when 0...15  then 0
        when 15...35 then 11
        when 35...49 then 12
        when 49...66 then 15
        else
          1
        end
      else
        case h
        when 21...42   then 8
        when 42...59   then 9
        when 59...84   then 7
        when 84...145  then v < 0.65 ? 5 : 13
        when 145...218 then 3
        when 218...264 then v < 0.60 ? 6 : 14
        when 264...325 then 4
        else
          v < 0.52 ? 2 : 10
        end
      end
    end

    # Convert 24-bit RGB value to HSV triplet (0-360, 0-1, 0-1)
    def self.rgb_to_hsv(rgb_value)
      r = ((rgb_value & 0xFF0000) >> 16) / 255.0
      g = ((rgb_value & 0x00FF00) >>  8) / 255.0
      b = (rgb_value & 0x0000FF) / 255.0
      max = [r, g, b].max
      min = [r, g, b].min
      delta = max - min
      v = max
      if (max > 0)
	s = delta / max
      else
	s = 0.0
      end
      if (s == 0.0)
	h = 0.0
      else
	if (r == max)
          h = (g - b) / delta
	elsif (g == max)
          h = 2 + (b - r) / delta
	elsif (b == max)
          h = 4 + (r - g) / delta
	end
	h *= 60.0
        h += 360.0 if h < 0
      end
      [h, s, v]
    end

  end
end
