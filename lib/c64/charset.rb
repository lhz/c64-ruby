# -*- coding: utf-8 -*-
require 'rubygame'

class C64::Charset

  SCREENCODE = {
    '@' =>  0, '[' => 27, '£' => 28, ']' => 29,
    '^' => 30, '«' => 31, ' ' => 32, '!' => 33,
    '"' => 34, '#' => 35, '$' => 36, '%' => 37,
    '&' => 38, "'" => 39, '(' => 40, ')' => 41,
    '*' => 42, "+" => 43, ',' => 44, '-' => 45,
    '.' => 46, '/' => 47, ':' => 58, ';' => 59,
    '<' => 60, '=' => 61, '>' => 62, '?' => 63,
  }
  ('a'..'z').each {|c| SCREENCODE[c] = c.ord - 'a'.ord + 1 }
  ('0'..'9').each {|c| SCREENCODE[c] = c.ord - '0'.ord + 1 }

  def initialize(filename)
    @surface = Rubygame::Surface.load(filename)
    make_char_rects
  end

  def make_char_rects
    @char_rects = Array.new(256)
    cols = @surface.width / 8
    rows = @surface.height / 8
    0.upto(rows - 1) do |row|
      0.upto(cols - 1) do |col|
        index = row * cols + col
        @char_rects[index] = Rubygame::Rect.new(col*8, row*8, 8, 8) if index < 256
      end
    end
  end

  def blit_char(target, pos, index, color)
    @surface.blit(target, pos, @char_rects[index])
  end

  def text_surface(text)
    surface = Rubygame::Surface.new([text.size * 8, 8], 0, HWSURFACE)
    text.downcase.each_char.with_index do |char, index|
      blit_char(surface, [8 * index, 0], SCREENCODE[char], 1)
    end
    surface
  end

end
