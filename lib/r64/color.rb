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
      from_rgb value >> 8
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

    def self.rgb_to_hsb(rgb_value)
      r = ((rgb_value & 0xFF0000) >> 16) / 255.0
      g = ((rgb_value & 0x00FF00) >>  8) / 255.0
      b = (rgb_value & 0x0000FF) / 255.0

      min, max = [r, g, b].minmax

      hue = Math.atan2(Math.sqrt(3) * (g - b), 2 * r - g - b)
      sat = [min, max].all?(&:zero?) ? 0.0 : ((max - min) / max * 100)
      brt = max

      [hue, sat, brt]
    end

    # R64::Color.palette.each { |k, v| puts "%06X: %2d %2d" % [k, v, R64::Color.guess_from_rgb(k)] }

    def self.guess_from_rgb(value)
      h, s, b = rgb_to_hsb(value)
      if s < 0.2
        case b * 100
        when 0...15  then 0
        when 15...37 then 11
        when 37...50 then 12
        when 50...75 then 15
        else
          1
        end
      else
        case h * 32
        when 3...9   then 3
        when 9...14  then (b < 0.62 ? 5 : 13)
        when 14...17 then 7
        when 17...19 then 9
        when 19...21 then 8
        when 21...25 then (b < 0.41 ? 2 : 10)
        when 25...30 then 4
        when 30...33 then
        else
          (b < 0.36 ? 6 : 14)
        end
      end
    end

  end
end
