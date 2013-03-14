module C64
  module Color

    module Names
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
    end

    include Names

    module Methods
      class ::Symbol
        def color
          C64::Color.from_symbol(self)
        end
      end
      class ::Fixnum
        def color(default = nil)
          C64::Color.from_rgb(self, default)
        end
        def rgb(palette = :pepto)
          C64::Color.to_rgb(self, palette)
        end
      end
    end

    def self.from_symbol(symbol)
      const_get symbol.to_s.upcase.to_sym
    end

    def self.from_rgb(value, default = nil)
      merged_palettes[value] || default || guess_from_rgb(value)
    end

    def self.from_rgba(value, default = nil)
      from_rgb value >> 8, default
    end

    def self.to_rgb(index, palette = :pepto)
      case palette
      when :vice     then palette_vice.key(index)
      when :vice_old then palette_vice_old.key(index)
      when :pepto    then palette_pepto.key(index)
      else
        raise "Invalid palette type :#{palette}."
      end
    end

    def self.xterm256_escape(index, bg = false)
      map = [
        0x10, 0x0f, 0x34, 0x06,
        0x05, 0x02, 0x13, 0xb9,
        0x5e, 0x3a, 0x83, 0xee,
        0xf3, 0x72, 0x3f, 0xf8,
      ]
      "\033[#{bg ? 48 : 38};5;#{map[index]}m"
    end

    def self.xterm256_dump(index, double = false)
      xterm256_escape(index, true) + (double ? "    " : "  ")
    end


    # "private"


    def self.merged_palettes
      @merged_palettes ||= palette_pepto.
        merge(palette_vice_old).
        merge(palette_vice)
    end

    def self.palette_vice_old
      { 0x000000 => BLACK,
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
        0x8F8F8F => LIGHT_GREY }
    end

    def self.palette_vice
      { 0x000000 => BLACK,
        0xFDFEFC => WHITE,
        0xBE1A24 => RED,
        0x30E6C6 => CYAN,
        0xB41AE2 => PURPLE,
        0x1FD21E => GREEN,
        0x211BAE => BLUE,
        0xDFF60A => YELLOW,
        0xB84104 => ORANGE,
        0x6A3304 => BROWN,
        0xFE4A57 => LIGHT_RED,
        0x424540 => DARK_GREY,
        0x70746F => MEDIUM_GREY,
        0x59FE59 => LIGHT_GREEN,
        0x5F53FE => LIGHT_BLUE,
        0xA4A7A2 => LIGHT_GREY }
    end

    def self.palette_pepto
      { 0x000000 => BLACK,
        0XFFFFFF => WHITE,
        0X68372B => RED,
        0X70A4B2 => CYAN,
        0X6F3D86 => PURPLE,
        0X588D43 => GREEN,
        0X352879 => BLUE,
        0XB8C76F => YELLOW,
        0X6F4F25 => ORANGE,
        0X433900 => BROWN,
        0X9A6759 => LIGHT_RED,
        0X444444 => DARK_GREY,
        0X6C6C6C => MEDIUM_GREY,
        0X9AD284 => LIGHT_GREEN,
        0X6C5EB5 => LIGHT_BLUE,
        0X959595 => LIGHT_GREY }
    end

    # Guess C64 color index from given 24-bit RGB value
    def self.guess_from_rgb(value)
      hue, sat, luma = rgb_to_hsl(value)
      if sat < 0.15
        case luma * 100
        when  0...10 then 0
        when 10...35 then 11
        when 35...51 then 12
        when 51...71 then 15
        else
          1
        end
      else
        case hue
        when 16...58   then luma < 0.28 ? 9 : 8
        when 58...84   then 7
        when 84...145  then luma < 0.60 ? 5 : 13
        when 145...218 then 3
        when 218...264 then luma < 0.31 ? 6 : 14
        when 264...325 then 4
        else
          luma < 0.38 ? 2 : 10
        end
      end
    end

    # Convert 24-bit RGB value to HSL triplet (0-360, 0-1, 0-1)
    def self.rgb_to_hsl(rgb_value)
      r = ((rgb_value & 0xFF0000) >> 16) / 255.0
      g = ((rgb_value & 0x00FF00) >>  8) / 255.0
      b = (rgb_value & 0x0000FF) / 255.0
      max = [r, g, b].max
      min = [r, g, b].min
      delta = max - min
      luma = (0.30 * r) + (0.59 * g) + (0.11 * b)
      if (max > 0)
	sat = delta / max
      else
	sat = 0.0
      end
      if (sat == 0.0)
	hue = 0.0
      else
	if (r == max)
          hue = (g - b) / delta
	elsif (g == max)
          hue = 2 + (b - r) / delta
	elsif (b == max)
          hue = 4 + (r - g) / delta
	end
	hue *= 60.0
        hue += 360.0 if hue < 0
      end
      [hue, sat, luma]
    end
  end
end
