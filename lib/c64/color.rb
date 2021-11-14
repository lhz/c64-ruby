require 'json'

module C64
  module Color

    CONFIG_LOCATIONS = [
      File.expand_path("./vic-palettes.json"),
      File.expand_path("~/.config/vic-palettes.json"),
    ]

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

    def self.read_palettes_json
      config_file = CONFIG_LOCATIONS.find { |path| File.exists?(path) } or
        raise "No palette config found at: #{CONFIG_LOCATIONS}"
      data = JSON.parse(File.read(config_file))
      data.each_with_object({}) do |(key, value), h|
        h[key.to_sym] = value.split(/\s*,\s*/).map(&:hex)
      end
    end

    def self.palettes
      @@palettes ||= read_palettes_json
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
      if palettes.has_key? palette
        palettes[palette][index]
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
      @merged_palettes ||= palettes.values.each_with_object({}) do |a, h|
        h.merge! Hash[a.map.with_index.to_a]
      end
    end

    # Guess C64 color index from given 24-bit RGB value and palette
    def self.closest_in_palette(value, palette)
      raise "Unknown palette '#{palette}'" unless palettes.key?(palette)
      vr, vg, vb = ((value & 0xFF0000) >> 16), ((value & 0xFF00) >> 8), value & 0xFF
      closest  = nil
      dist_min = 9
      palettes[palette].each_with_index do |p, i|
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
