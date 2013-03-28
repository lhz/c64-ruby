require 'chunky_png'
require 'matrix'
require 'c64/color'

module C64
  class Image

    attr_reader :bitmap, :colmap, :screen

    # Read image/frames from given filename
    def initialize(filename)
      @png = ChunkyPNG::Image.from_file(filename)
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
      check_bounds(x, y)
      pixels[y, x]
    end

    # Modify the color index of a pixel
    def []=(x, y, color)
      pixels unless @pixels
      check_bounds(x, y)
      @pixels[y, x] = color
      if pixel_width == 2
        @pixels[y, (x % 2 == 0) ? x + 1 : x - 1] = color
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


    # private


    def check_bounds(x, y)
      raise IndexError.new if !within_bounds?(x, y)
    end

    def double_pixels_detected?(options = {})
      if options[:fast]
        [width - 1, height].min.times.all? { |i|
          self[i, i] == self[i, i + 1]
        }
      else
        height.times.all? { |y|
          0.step(width - 1, 2).all? { |x|
            self[x, y] == self[x + 1, y]
          }
        }
      end
    end

    # Rectangle surrounding the complete image
    def full_rectangle
      upper_left  = Point[0, 0]
      lower_right = Point[width - 1, height - 1]
      Rectangle[upper_left, lower_right]
    end

    # Convert image to two-dimentional array of C64 color indexes
    def pixels(rect = full_rectangle)
      @pixels ||= Matrix.build(rect.height, rect.width) do |y, x|
        C64::Color.from_rgba @png[x, y]
      end
    end

    # Find a color inside a list of (lists of) colors
    # Return index + 1 or 0 if not found
    def lookup_color(c, clist)
      clist.each_with_index do |ci, i|
        return (i + 1) if ci == c || (ci.is_a?(Array) && ci.include?(c))
      end
      return 0
    end

    # Extract multicolor charset
    def charset_multi(x, y, cols, rows, clist)
      pixel_matrix :x => x, :y => y, :w => 8 * cols, :h => 8 * rows # , :debug => true
      Matrix.build(rows, cols).flat_map do |r, c|
        char_multi 8 * c, 8 * r, clist
      end
    end

    # Extract hires charset
    def charset_hires(x, y, cols, rows, color)
      pixel_matrix :x => x, :y => y, :w => 8 * cols, :h => 8 * rows # , :debug => true
      Matrix.build(rows, cols).flat_map do |r, c|
        char_hires 8 * c, 8 * r, color
      end
    end

    # Extract char (8 byte rows) from multicolor pixels
    def char_multi(x, y, clist)
      (0..7).map {|r| byte_multi(x, y + r, clist) }
    end

    # Extract char (8 byte rows) from multicolor pixels
    def char_hires(x, y, c)
      (0..7).map {|r| byte_hires(x, y + r, c) }
    end

    # Extract byte value of multicolor pixels
    def byte_multi(x, y, clist)
      @pixels[y, x..(x+3)].each_with_object([0, 64]) { |c, o|
        o[0] += o[1] * lookup_color(c, clist)
        o[1] >>= 2
      }[0]
    end

    # Extract byte value of singlecolor pixels
    def byte_hires(x, y, color)
      # puts "C64::Image#byte_hires: x=#{x}, y=#{y}, color=#{color}"
      # puts "  pixels: #{@pixels[y][x, 8].inspect}"
      @pixels[y, x..(x+7)].each_with_object([0, 128]) { |c, o|
        o[0] += o[1] if c == color
        o[1] >>= 1
      }[0]
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

    def cell_multi(column, row, bcol = 0)
      cpix = Matrix.build(8, 4).flat_map do |y, x|
        pixels[8 * row + y, 8 * column + pixel_width * x]
      end
      cols = (most_used_colors(cpix, bcol) + [bcol] * 3).first(3).sort
      bytes = 8.times.map do |y|
        4.times.map do |x|
          mask = 2 ** (6 - x * 2)
          c = cpix[y * 4 + x]
          if c != bcol && !cols.include?(c)
            c = nearest_color_in_set(c, cols + [bcol])
          end
          mask * ((cols.index(c) || -1) + 1)
        end.reduce(:+)
      end
      [cols[0] * 16 + cols[1], cols[2], bytes]
    end

    # Calculate histogram data of pixel color distribution
    def histogram
      pixarr = @pixels.to_a.flatten
      Hash[16.times.map {|c| [c, pixarr.count(c)] }]
    end

    # Extract a set of sprites
    def sprites(x, y, cols, rows, clist)
      Matrix.build(rows, cols) { |r, c|
        to_sprite :x => x + c * 24, :y => y + r * 21, :w => 24, :h => 21, :color => clist
      }.to_a.flatten
    end

    # Extract sprite data
    def sprite(opt)
      opt[:w] ||= (double_pixels? ? 48 : 24)
      opt[:h] ||= 21
      if opt[:color].is_a?(Array)
        sprite_mc(opt)
      else
        sprite_sc(opt)
      end
    end

    # Extract sprite data for single color sprite
    def sprite_sc(opt)
      puts "sprite_sc: opt = #{opt.inspect}" if opt[:debug]
      x = opt[:x] || 0
      y = opt[:y] || 0
      c = opt[:color]
      data = Array.new(64){0}
      pix_arr = pixel_matrix(opt.merge(:force => true))
      0.upto(opt[:h] - 1) do |row|
        next if y + row < 0 || y + row >= height
        0.upto(opt[:w] - 1) do |col|
          next if x + col < 0 || x + col >= width
          byte_index = row * 3 + (col / 8)
          bit_mask   = 2 ** (7 - (col % 8))
          data[byte_index] += bit_mask if pix_arr[row][col] == c
        end
      end
      puts "sprite_sc:\n opt: #{opt.inspect}\n#{dump_sprite_sc(pix_arr, data)}" if opt[:debug]
      data
    end

    # Extract sprite data for multicolor sprite
    def sprite_mc(opt)
      x = opt[:x] || 0
      y = opt[:y] || 0
      spc, mc1, mc2 = opt[:color]
      pix_arr = pixel_matrix(opt.merge(:force => true))
      # dump_pixels(pix_arr) if opt[:debug]
      data = Array.new(64) { 0 }
      0.upto(opt[:h] - 1) do |row|
        next if y + row < 0 || y + row >= height
        0.upto(opt[:w] / 2) do |col|
          next if x + col < 0 || x + col >= width
          byte_index = row * 3 + (col / 4)
          bit1_mask  = 2 ** (7 - (col % 4) * 2)
          bit2_mask  = 2 ** (6 - (col % 4) * 2)
          case pix_arr[row][col]
          when spc then
            data[byte_index] += bit1_mask
          when mc1 then
            data[byte_index] += bit2_mask
          when mc2 then
            data[byte_index] += bit1_mask + bit2_mask
          end
        end
      end
      data
    end

    def convert_hires_bitmap
      @bitmap = Array.new(8000) { 0 }
      @screen = Array.new(1000) { 0 }
      pixels = pixel_matrix
      0.upto(charheight - 1) do |r|
        0.upto(charwidth - 1) do |c|
          cpix = (0..7).map { |y|
            (0..7).map { |x| pixels[r * 8 + y][c * 8 + x] }
          }
          ccols = cpix.flatten.uniq.sort
          next if ccols.empty?
          ccols.size <= 2 or
            $stderr.puts "Too many colors at (#{c*8},#{r*8}): #{ccols.join(',')}"
          ccols.unshift 0 while ccols.size < 2
          # puts "r=#{r}, c=#{c}, ccols=#{ccols.inspect}"
          @screen[r * 40 + c] = ccols[1] * 16 + ccols[0]
          0.upto(7) do |y|
            byte = 0
            0.upto(7) do |x|
              mask = 2 ** (7 - x)
              byte += mask if cpix[y][x] != ccols[0]
            end
            @bitmap[r * 320 + c * 8 + y] = byte
          end
        end
      end
    end

    # Convert image to C64 multicolor bitmap
    def convert_multicolor_bitmap(options = {})
      cols = options[:cols] || charwidth
      rows = options[:rows] || charheight
      xoff = options[:xoff] || 0
      yoff = options[:yoff] || 0
      bcol = options[:bcol] || 0
      @bitmap = Array.new(cols * rows * 8) { 0 }
      @colmap = Array.new(cols * rows) { 0 }
      @screen = Array.new(cols * rows) { 0 }
      pixels = pixel_matrix
      0.upto(rows - 1) do |r|
        0.upto(cols - 1) do |c|
          cpix = (0..7).map { |y|
            (0..3).map { |x|
              pixels[r * 8 + yoff + y][c * 4 + xoff + x]
            }
          }
          if options[:optimize]
            ccols = most_used_colors(cpix.flatten, bcol).first(3).sort
          else
            ccols = cpix.flatten.uniq.sort - [bcol]
            ccols.size <= 3 or
              $stderr.puts "Too many colors at (#{c*8+xoff},#{r*8+yoff}): #{ccols.join(',')}"
          end
          next if ccols.empty?
          ccols += [4] while ccols.size < 3
          screen[r * 40 + c] = ccols[0] * 16 + ccols[1]
          colmap[r * 40 + c] = ccols[2]
          0.upto(7) do |y|
            byte = 0
            0.upto(3) do |x|
              mask = 2 ** (6 - x * 2)
              color = cpix[y][x]
              if options[:optimize] && color != bcol && !ccols.include?(color)
                color = nearest_color_in_set(color, ccols + [bcol])
              end
              case color
              when ccols[0]
                byte += mask
              when ccols[1]
                byte += mask * 2
              when ccols[2]
                byte += mask * 3
              end
            end
            bitmap[r * 320 + c * 8 + y] = byte
          end
        end
      end
    end

    def extract_multicolor_chars(col, row, ncols, nrows, c1, c2, c3)
      screen = Array.new(1000) { 0 }
      pixels = pixel_matrix
      char_index = Hash.new
      current_char = 0
      row.upto(row + nrows - 1) do |r|
        col.upto(col + ncols - 1) do |c|
          #puts "r:#{r}, c:#{c}"
          cpix = (0..7).map { |y|
            (0..3).map { |x| pixels[r * 8 + y][c * 4 + x] }
          }
          char_bytes = (0..7).map do |y|
            byte = 0
            0.upto(3) do |x|
              mask = 2 ** (6 - x * 2)
              color = cpix[y][x]
              if c1 == color || (c1.is_a?(Array) && c1.include?(color))
                byte += mask
              elsif c2 == color || (c2.is_a?(Array) && c2.include?(color))
                byte += mask * 2
              elsif c3 == color || (c3.is_a?(Array) && c3.include?(color))
                byte += mask * 3
              end
            end
            byte
          end
          if existing_char = char_index[char_bytes]
            screen[r * 40 + c] = existing_char
          else
            char_index[char_bytes] = current_char
            screen[r * 40 + c] = current_char
            current_char += 1
          end
        end
      end
      chrset = char_index.sort_by{|k,v|v}.map{|k,v|k}.flatten
      [screen, chrset]
    end

    def extract_multicolor_chars_2(col, row, ncols, nrows, c1, c2, c3)
      screen = Array.new(ncols*nrows) { 0 }
      pixels = pixel_matrix
      char_index = Hash.new
      current_char = 0
      row.upto(row + nrows - 1) do |r|
        col.upto(col + ncols - 1) do |c|
          cpix = (0..7).map { |y|
            (0..3).map { |x| pixels[r * 8 + y][c * 4 + x] }
          }
          char_bytes = (0..7).map do |y|
            byte = 0
            0.upto(3) do |x|
              mask = 2 ** (6 - x * 2)
              color = cpix[y][x]
              if c1 == color || (c1.is_a?(Array) && c1.include?(color))
                byte += mask
              elsif c2 == color || (c2.is_a?(Array) && c2.include?(color))
                byte += mask * 2
              elsif c3 == color || (c3.is_a?(Array) && c3.include?(color))
                byte += mask * 3
              end
            end
            byte
          end
          if existing_char = char_index[char_bytes]
            screen[(r - row) * ncols + (c - col)] = existing_char
          else
            char_index[char_bytes] = current_char
            screen[(r - row) * ncols + (c - col)] = current_char
            current_char += 1
          end
        end
      end
      chrset = char_index.sort_by{|k,v|v}.map{|k,v|k}.flatten
      [screen, chrset]
    end

    def fix_color_bugs(filename, bcol = 0)
      cols = charwidth
      rows = charheight
      source = pixel_matrix
      target = Array.new(height) { Array.new(width) }
      changed = 0
      0.upto(charheight - 1) do |r|
        0.upto(charwidth - 1) do |c|
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

    # Set palette
    def self.palette=(palette)
      #puts "Setting palette"
      @palette = palette
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

  end
end
