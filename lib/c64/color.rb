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

    # FIXME: Move most of this stuff to a config file or something (JSON?)
    PALETTES = {
      vice_new: [
        0x000000, 0xffffff, 0xb85438, 0x8decff, 0xba56e4, 0x79d949, 0x553ee5, 0xfbff79,
        0xbd7c1b, 0x7e6400, 0xf29580, 0x6f716e, 0xa2a4a1, 0xcdff9d, 0xa18aff, 0xd3d5d2,
      ],
      colodore: [
        0x000000, 0xffffff, 0x813338, 0x75cec8, 0x8e3c97, 0x56ac4d, 0x2e2c9b, 0xedf171,
        0x8e5029, 0x553800, 0xc46c71, 0x4a4a4a, 0x7b7b7b, 0xa9ff9f, 0x706deb, 0xb2b2b2
      ],
      pepto: [
        0x000000, 0xffffff, 0x68372b, 0x70a4b2, 0x6f3d86, 0x588d43, 0x352879, 0xb8c76f,
        0x6f4f25, 0x433900, 0x9a6759, 0x444444, 0x6c6c6c, 0x9ad284, 0x6c5eb5, 0x959595
      ],
      vice: [
        0x000000, 0xfdfefc, 0xbe1a24, 0x30e6c6, 0xb41ae2, 0x1fd21e, 0x211bae, 0xdff60a,
        0xb84104, 0x6a3304, 0xfe4a57, 0x424540, 0x70746f, 0x59fe59, 0x5f53fe, 0xa4a7a2,
      ],
      vice_old: [
        0x000000, 0xd5d5d5, 0x72352c, 0x659fa6, 0x733a91, 0x568d35, 0x2e237d, 0xaeb75e,
        0x774f1e, 0x4b3c00, 0x9c635a, 0x474747, 0x6b6b6b, 0x8fc271, 0x675db6, 0x8f8f8f,
      ],
      vice_shot: [
        0x000000, 0xffffff, 0xae593f, 0x9ce9fc, 0xaf5bec, 0x88d63e, 0x553ee5, 0xfeff75,
        0xb68119, 0x7a6600, 0xe79a84, 0x727272, 0xa4a4a4, 0xd5ff97, 0x9f8bff, 0xd5d5d5,
      ],
      levy: [
        0x040204, 0xfcfefc, 0xcc3634, 0x84f2dc, 0xcc5ac4, 0x5cce34, 0x4436cc, 0xf4ee5c,
        0xd47e34, 0x945e34, 0xfc9a94, 0x5c5a5c, 0x8c8e8c, 0x9cfe9c, 0x74a2ec, 0xc4c2c4,
      ],
      timanthes: [
        0x000000, 0xffffff, 0xbb6a51, 0xa9f3ff, 0xbf6efb, 0x98e551, 0x6953f5, 0xffff7b,
        0xc69232, 0x8d7900, 0xf5ab96, 0x818181, 0xb6b6b6, 0x9cfe9c, 0xb19eff, 0xe0e0e0,
      ],
      ilkke: [
        0x000000, 0xffffff, 0xa0292f, 0x59dcd4, 0xa82cb7, 0x3fc033, 0x2926d3, 0xf5f841,
        0xa84a14, 0x643800, 0xe56067, 0x4a4a4a, 0x7b7b7b, 0x8fff81, 0x6a66ff, 0xb2b2b2,
      ],

      unknown_a: [
        0x000000, 0xffffff, 0x894036, 0x7abfc7, 0x8a46ae, 0x68a941, 0x3e31a2, 0xd0dc71,
        0x905f25, 0x5c4700, 0xbb776d, 0x555555, 0x808080, 0xacea88, 0x7c70da, 0xababab,
      ],
      timanthes_variant_a: [
        0x000000, 0xffffff, 0xbb6a51, 0xa9f3ff, 0xbf6efb, 0x98e551, 0x6953f5, 0xffff7b,
        0xc69232, 0x8d7900, 0xf5ab96, 0x818181, 0xb6b6b6, 0xdbff9e, 0xb19eff, 0xe0e0e0,
      ],
      timanthes_variant_b: [
        0x000000, 0xffffff, 0x924a40, 0x84c5cc, 0x9351b6, 0x72b14b, 0x483aaa, 0xd5df7c,
        0x99692d, 0x675200, 0xc18178, 0x606060, 0x8a8a8a, 0xb3ec91, 0x867ade, 0xb3b3b3,
      ],
      vice_variant_a: [
        0x000000, 0xffffff, 0xb85438, 0x8decff, 0xba56e4, 0x79d949, 0x553de1, 0xfbff79,
        0xbd7c1b, 0x7e6400, 0xf29580, 0x6f716e, 0xa2a4a1, 0xcdff9d, 0xa18aff, 0xd3d5d2,
      ],
      vice_variant_b: [
        0x000000, 0xffffff, 0xb85438, 0x8decff, 0xba56e4, 0x7fce33, 0x553de1, 0xfbff79,
        0xad780a, 0x705c00, 0xf29580, 0x6f716e, 0xa2a4a1, 0xcdff8e, 0xa18aff, 0xd3d5d2,
      ],
      jazzcat: [
        0x000000, 0xffffff, 0x9f5541, 0x93d9ec, 0xa45bc4, 0x7ac559, 0x5841bb, 0xeafd88, 
        0xa47631, 0x6e5d00, 0xd5907c, 0x6b6b6b, 0x9a9a9a, 0xc4ffa5, 0x9a86fa, 0xc7c7c7,
      ],
    }

    module CoreExtensions
      def self.included(base)
        Symbol.class_eval do
          def color
            C64::Color.from_symbol(self)
          end
        end
        Integer.class_eval do
          def color(default = nil)
            C64::Color.from_rgb(self, default)
          end
          def rgb(palette = :pepto)
            C64::Color.to_rgb(self, palette)
          end
          def rgbs(palette = :pepto)
            "#%06X" % C64::Color.to_rgb(self, palette)
          end
        end
      end
    end

    def self.[](value)
      index = (value.is_a?(Symbol) ? from_symbol(value) : value)
      to_rubygame_color to_rgb(index)
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
      if PALETTES.has_key? palette
        PALETTES[palette][index]
      else
        raise "Invalid palette key :#{palette}."
      end
    end

    def self.to_rubygame_color(rgb_value)
      require 'rubygame'
      r = ((rgb_value & 0xFF0000) >> 16) / 255.0
      g = ((rgb_value & 0x00FF00) >>  8) / 255.0
      b = (rgb_value & 0x0000FF) / 255.0
      Rubygame::Color::ColorRGB.new([r, g, b])
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


    # Hash of all palettes merged with RGB as keys and index as value
    def self.merged_palettes
      @merged_palettes ||= PALETTES.values.each_with_object({}) do |a, h|
        h.merge! Hash[a.map.with_index.to_a]
      end
    end

    # Guess C64 color index from given 24-bit RGB value and palette
    def self.closest_in_palette(value, palette)
      raise "Unknown palette '#{palette}'" unless PALETTES.key?(palette)
      vr, vg, vb = ((value & 0xFF0000) >> 16), ((value & 0xFF00) >> 8), value & 0xFF
      closest  = nil
      dist_min = 9
      PALETTES[palette].each_with_index do |p, i|
        pr, pg, pb = ((p & 0xFF0000) >> 16), ((p & 0xFF00) >> 8), p & 0xFF
        dist = (((pr - vr) / 256.0) ** 2) +
               (((pg - vg) / 256.0) ** 2) +
               (((pb - vb) / 256.0) ** 2)
        if dist < dist_min
          dist_min = dist
          closest  = i
        end
      end
      closest
    end

    # Guess C64 color index from given 24-bit RGB value
    def self.guess_from_rgb(value)
      hue, sat, luma = rgb_to_hsl(value)
      if luma < 0.07
        0
      elsif sat < 0.15
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
    def self.rgb_to_hsl(rgb24)
      r, g, b = [16, 8, 0].map {|n| ((rgb24 >> n) & 255) / 255.0 }
      min, max = [r, g, b].minmax
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
	hue = (hue * 60.0) % 360
      end
      [hue, sat, luma]
    end

    # Convert HSL triplet (0-360, 0-1, 0-1) to 24-bit RGB value
    def self.hsl_to_rgb(h, s, l)
      m2 = (l <= 0.5) ? l * (s + 1) : l + s - l * s
      m1 = l * 2.0 - m2;

      hue2rgb = lambda do |m1x, m2x, hx|
        hx = (hx < 0) ? hx + 1 : ((hx > 1) ? hx - 1 : hx)
        if (hx * 6.0 < 1)
          m1x + (m2x - m1x) * hx * 6.0
        elsif (hx * 2.0 < 1)
          m2x
        elsif (hx * 3.0 < 2)
          m1x + (m2x - m1x) * (0.666666666666666 - hx) * 6.0
        else
          m1x
        end
      end
      r = Integer(255.999 * hue2rgb.call(m1, m2, h + 0.333333333333333))
      g = Integer(255.999 * hue2rgb.call(m1, m2, h))
      b = Integer(255.999 * hue2rgb.call(m1, m2, h - 0.333333333333333))
      (r << 16) + (b << 8) + b
    end
  end
end
