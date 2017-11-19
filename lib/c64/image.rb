require 'chunky_png'
require 'matrix'
require 'c64/color'

module C64
  class Image

    attr_reader :bitmap, :colmap, :screen
    attr_writer :debug, :xoffset, :yoffset

    # Read image/frames from given filename
    def initialize(filename)
      @png = ChunkyPNG::Image.from_file(filename)
      @debug = [] # [:double_pixels_detected?]
      @xoffset = 0
      @yoffset = 0
      @method = :guess
      @method_param = nil
    end

    def method_closest(palette)
      @method = :closest
      @method_param = palette
    end

    # Width of image in pixels
    def width
      @png.width
    end

    # Height of image in pixels
    def height
      @png.height
    end

    # Width of image in chars
    def char_width
      (width / 8.0).ceil
    end

    # Height of image in chars
    def char_height
      (height / 8.0).ceil
    end

    # Width of a pixel (1 for hires, 2 for multicolor)
    def pixel_width
      @pixel_width ||= (double_pixels_detected? ? 2 : 1)
    end

    # Set pixel width
    def pixel_width=(value)
      if value == 1 || value == 2
        @pixel_width = value
      else
        raise "Pixel width must be 1 or 2!"
      end
    end

    # Read the color index of a pixel
    def [](x, y)
      check_bounds(x + @xoffset, y + @yoffset)
      pixels[y + @yoffset, x + @xoffset]
    end

    # Modify the color index of a pixel
    def []=(x, y, color)
      pixels unless @pixels
      check_bounds(x + @xoffset, y + @yoffset)
      @pixels[y + @yoffset, x + @xoffset] = color
      if pixel_width == 2
        @pixels[y + @yoffset, (x % 2 == 0) ? x + @xoffset + 1 : x + @xoffset - 1] = color
      end
    end

    def within_bounds?(x, y)
      x >= 0 && x < width && y >= 0 && y < height
    end

    def save_png(filename, palette = :pepto)
      png = ChunkyPNG::Image.new(width, height)
      height.times do |y|
        width.times do |x|
          png[x, y] = ((C64::Color.to_rgb(pixels[y, x], palette) << 8) | 0xFF)
        end
      end
      png.save(filename)
    end

    def png_blob(palette = :pepto)
      png = ChunkyPNG::Image.new(width, height)
      height.times do |y|
        width.times do |x|
          png[x, y] = ((C64::Color.to_rgb(pixels[y, x], palette) << 8) | 0xFF)
        end
      end
      png.to_blob
    end

    # private


    def check_bounds(x, y)
      raise IndexError.new if !within_bounds?(x, y)
    end

    def double_pixels_detected?(options = {})
      if options[:fast]
        double = [width / 2, height].min.times.all? { |i|
          # self[i, i] == self[i, i + 1]
          @png[i * 2, i] == @png[i * 2 + 1, i]
        }
      else
        double = height.times.all? { |y|
          0.step(width - 1, 2).all? { |x|
            # self[x, y] == self[x + 1, y]
            @png[x, y] == @png[x + 1, y]
          }
        }
      end
      debug __method__, {double: double}
      double
    end

    # Rectangle surrounding the complete image
    def full_rectangle
      upper_left  = Point[0, 0]
      lower_right = Point[width - 1, height - 1]
      Rectangle[upper_left, lower_right]
    end

    # Convert image to two-dimentional array of C64 color indexes
    def pixels(rect = full_rectangle)
      cmap = {}
      if @method == :closest
        @pixels ||= Matrix.build(rect.height, rect.width) do |y, x|
          value = @png[x, y] >> 8
          if cmap.key?(value)
            cmap[value]
          else
            index = C64::Color.closest_in_palette(@png[x, y] >> 8, @method_param)
            # puts "CMAP: #{value.to_s(16)} => #{index}"
            cmap[value] = index
          end
        end
      else
        @pixels ||= Matrix.build(rect.height, rect.width) do |y, x|
          value = @png[x, y]
          cmap[value] ||= C64::Color.from_rgba value
        end
      end
    end

    # Find a color inside a list of (lists of) colors
    # Return index + 1 or 0 if not found
    def lookup_color(c, clist)
      debug(:lookup_color, {c: c, clist: clist})
      clist.each_with_index do |ci, i|
        return (i + 1) if ci == c || (ci.is_a?(Array) && ci.include?(c))
      end
      return 0
    end

    # Extract multicolor charset
    def charset_multi(x, y, cols, rows, clist)
      # pixel_matrix :x => x, :y => y, :w => 8 * cols, :h => 8 * rows # , :debug => true
      Matrix.build(rows, cols).flat_map do |r, c|
        char_multi x + 8 * c, y + 8 * r, clist
      end
    end

    # Extract hires charset
    def charset_hires(x, y, cols, rows, color)
      # pixel_matrix :x => x, :y => y, :w => 8 * cols, :h => 8 * rows # , :debug => true
      Matrix.build(rows, cols).flat_map do |r, c|
        char_hires x + 8 * c, y + 8 * r, color
      end
    end

    # Extract a grid of sprites
    def sprite_grid(args)
      args = {x0: 0, y0: 0, dx: 24, dy: 21}.merge(args)
      Matrix.build(args[:rows], args[:columns]).flat_map do |r, c|
        x, y = args[:x0] + c * args[:dx], args[:y0] + r * args[:dy]
        sprite x: x, y: y, color: args[:color]
      end
    end

    # Extract a sprite
    def sprite(args)
      args = {x: 0, y: 0, color: 1, w: 24, h: 21}.merge(args)
      debug __method__, args
      Matrix.build(21, 3).flat_map do |r, c|
        method = (args[:color].is_a?(Array) ? :byte_multi : :byte_hires)
        send method, args[:x] + 8 * c, args[:y] + r, args[:color]
      end << 0
    end

    # Extract char (8 byte rows) from multicolor pixels
    def char_multi(x, y, clist)
      (0..7).map {|r| byte_multi(x, y + r, clist) }
    end

    # Extract char (8 byte rows) from multicolor pixels
    def char_hires(x, y, c)
      (0..7).map {|r| byte_hires(x, y + r, c) }
    end

    # Extract byte value of 4 multicolor pixels
    def byte_multi(x, y, clist)
      debug __method__, {x: x, y: y, clist: clist}
      colors = [1, 0, 2].map {|i| clist[i] }
      4.times.map { |n|
        # puts "XXX: byte_multi: pixel y=#{y}, x=#{xx}"
        pixels[y + @yoffset, x + @xoffset + n * pixel_width]
      }.each_with_object([0, 64]) { |c, o|
        o[0] += o[1] * lookup_color(c, colors)
        o[1] >>= 2
      }[0]
    end

    # Extract byte value of 8 hires pixels
    def byte_hires(x, y, color)
      debug __method__, {x: x, y: y, color: color}
      pixels[y + @yoffset, (x + @yoffset)..(x + @xoffset + 7)].each_with_object([0, 128]) { |c, o|
        o[0] += o[1] if c == color
        o[1] >>= 1
      }[0]
    end

    def write_bitmap_multi(base_path, bcol, addr)
      koala = to_koala(bcol)
      range = { :bitmap => 0..7999, :screen => 8000..8999, :colmap => 9000..9999 }
      [:bitmap, :screen, :colmap].each do |part|
        File.open("#{base_path}-#{part}.bin", 'wb') do |bm|
          bm.write [addr[part]].pack('S')
          bm.write koala[range[part]].pack('C*')
        end
      end
    end

    def write_bitmap_hires(base_path, addr)
      hires = to_hires
      range = { :bitmap => 0..7999, :screen => 8000..8999 }
      [:bitmap, :screen].each do |part|
        File.open("#{base_path}-#{part}.bin", 'wb') do |bm|
          bm.write [addr[part]].pack('S')
          bm.write hires[range[part]].pack('C*')
        end
      end
    end

    def to_koala(bcol)
      cells = Matrix.build(25, 40).map do |row, column|
        cell_multi(column, row, bcol)
      end
      screen = cells.map {|c| c[0] }
      colmap = cells.map {|c| c[1] }
      bitmap = cells.flat_map {|c| c[2] }
      bitmap + screen + colmap + [bcol]
    end

    def to_hires(opts = {})
      cells = Matrix.build(25, 40).map do |row, column|
        cell_hires(column, row, opts)
      end
      screen = cells.map {|c| c[0] }
      bitmap = cells.flat_map {|c| c[1] }
      bitmap + screen
    end

    # def cell_multi?(column, row, bcol = 0)
    #   cpix = Matrix.build(8, 8).flat_map do |y, x|
    #     pixels[8 * row + y + @yoffset, 8 * column + x + @xoffset]
    #   end
    #   puts cpix.inspect
    #   cpix.each.with_index do |p, i|
    #     return false if i.odd? && p[i] != p[i - 1]
    #   end
    #   return true
    # end

    def cpix(column, row)
      cpix = Matrix.build(8, 4).flat_map do |y, x|
        pixels[8 * row + y + @yoffset, 8 * column + pixel_width * x + @xoffset]
      end
    end

    def cell_multi(column, row, bcol = 0, sort_first = false)
      cpix = Matrix.build(8, 4).flat_map do |y, x|
        pixels[8 * row + y + @yoffset, 8 * column + pixel_width * x + @xoffset]
      end
      if sort_first
        cols = (most_used_colors(cpix, bcol).sort + [bcol] * 3).first(3)
      else
        cols = (most_used_colors(cpix, bcol) + [bcol] * 3).first(3).sort
      end
      debug __method__, {column: column, row: row, bcol: bcol, cols: cols.inspect, cpix: cpix.inspect }
      bytes = 8.times.map do |y|
        4.times.map do |x|
          mask = 2 ** (6 - x * 2)
          c = cpix[y * 4 + x]
          if c != bcol && !cols.include?(c)
            c = nearest_color_in_set(c, cols + [bcol])
          end
          c == bcol ? 0 : mask * ((cols.index(c) || -1) + 1)
        end.reduce(:+)
      end
      [cols[0] * 16 + cols[1], cols[2], bytes]
    end

    def cell_hires(column, row, opts = {})
      cpix = Matrix.build(8, 8).flat_map do |y, x|
        pixels[8 * row + y + @yoffset, 8 * column + pixel_width * x + @xoffset]
      end
      if opts[:sort_first]
        cols = (most_used_colors(cpix, nil).sort + [0] * 2).first(2)
      else
        cols = (most_used_colors(cpix, nil) + [0] * 3).first(2).sort
      end
      bytes = 8.times.map do |y|
        8.times.map do |x|
          mask = 2 ** (7 - x)
          c = cpix[y * 8 + x]
          c = nearest_color_in_set(c, cols) if !cols.include?(c)
          mask * (cols.index(c) || 0)
        end.reduce(:+)
      end
      debug __method__, {column: column, row: row, cols: cols.inspect, cpix: cpix.inspect, bytes: bytes.inspect }
      [cols[1] * 16 + cols[0], bytes]
    end

    # Calculate histogram data of pixel color distribution
    def histogram
      pixarr = @pixels.to_a.flatten
      Hash[16.times.map {|c| [c, pixarr.count(c)] }]
    end

    def fix_color_bugs(filename, bcol = 0)
      cols = char_width
      rows = char_height
      source = pixel_matrix
      target = Array.new(height) { Array.new(width) }
      changed = 0
      0.upto(char_height - 1) do |r|
        0.upto(char_width - 1) do |c|
          cpix = (0..7).map { |y|
            (0..3).map { |x|
              source[r * 8 + y][c * 4 + x]
            }
          }
          ccols = most_used_colors(cpix.flatten, bcol).first(3)
          ccols += [4] while ccols.size < 3
          0.upto(7) do |y|
            byte = 0
            0.upto(3) do |x|
              mask = 2 ** (6 - x * 2)
              color = cpix[y][x]
              if color != bcol && !ccols.include?(color)
                color = nearest_color_in_set(color, ccols + [bcol])
                changed += 1
              end
              #target[r * 8 + y][c * 8 + x*2]     = color
              #target[r * 8 + y][c * 8 + x*2 + 1] = color
              target[r * 8 + y][c * 8 + x * 2]     = color
              target[r * 8 + y][c * 8 + x * 2 + 1] = color
            end
          end
        end
      end
      if changed > 0
        puts "Changed #{changed} pixels, outputting modified image to #{filename}."
        pixels = target.flatten.map {|c| C64::Color.palette_rgb[c].pack('C3') }.join
        @image.import_pixels(0, 0, width, height, 'RGB', pixels)
        @image.write filename
      end
    end

    private

    def dump_sprite_sc(pa, sd)
      (0..20).map { |r|
        pstr = pa[r].map { |c|
          case c
          when 0..15
            c.to_s(16)
          else
            '-'
          end
        }.join('')
        dstr = sd[r*3..r*3+2].map{|b|('0000000' + b.to_s(2))[-8..-1]}.join(',')
        [pstr, dstr].join("   ")
      }.join("\n")
    end

    def dump_pixels(pixels)
      pixels.each do |row|
        if ENV['TERM'] =~ /256/
          puts row.map {|p| C64::Color.xterm_dump(p, double_pixels?) }.join + "\033[0m"
        else
          puts row.map {|p| p.to_s(16) }.join
        end
      end
    end

    def nearest_color_in_set(color, set)
      debug __method__, { color: color, set: set.inspect }
      lum = [0, 255, 80, 159, 96, 128, 64, 191, 96, 64, 128, 80, 120, 191, 120, 159]
      set.min_by {|c| (lum[c] - lum[color]).abs }
    end

    def most_used_colors(array, bcol = 0)
      array.flatten.reject {|c|
        c == bcol
      }.each_with_object(Hash.new() { 0 }) {|c, h|
        h[c] += 1
      }.sort_by {|k, v| -v}.map(&:first)
    end

    def debug(method, args)
      if @debug.include?(method)
        puts "C64::Image#debug: #{method} #{args.inspect}"
      end
    end

  end
end
