require 'rubygame'
require 'c64/color'

class C64::ScaledScreen < Rubygame::Screen

  attr_accessor :border_color
  attr_accessor :screen_color
  attr_accessor :charset
  attr_accessor :surface
  attr_accessor :border
  attr_accessor :scale

  def initialize(options = {})
    self.scale = options[:scale] || 2
    self.title = options[:title] || 'C64 Screen'
    self.border = options[:border].nil? ? true : options[:border]
    color = options[:color] || {}
    self.border_color = color[:border] || :light_blue
    self.screen_color = color[:screen] || :blue
    self.surface = Rubygame::Surface.new([total_width, total_height],
                                         0, [Rubygame::HWSURFACE])
    super([scale * total_width, scale * total_height],
          0, [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF])
  end

  def flip
    surface.zoom(scale).blit self, [0, 0]
    super
  end

  def total_width
    320 + border_width * 2
  end

  def total_height
    200 + border_top_height + border_bottom_height
  end

  def border_width
    border ? 32 : 0
  end

  def border_top_height
    border ? 35 : 0
  end

  def border_bottom_height
    border ? 37 : 0
  end

  def outer_upper_left
    [0, 0]
  end

  def outer_bottom_right
    [total_width - 1, total_height - 1]
  end

  def inner_upper_left
    [border_width, border_top_height]
  end

  def inner_bottom_right
    [border_width + 319, border_top_height + 199]
  end

  def color_by_index(index)
    C64::Color[index]
  end

  def draw_rect(xpos, ypos, width, height, color)
    surface.draw_box(inner_point(xpos, ypos),
                     inner_point(xpos + width - 1, ypos + height - 1),
                     color_by_index(color))
  end

  def fill_rect(xpos, ypos, width, height, color)
    surface.draw_box_s(inner_point(xpos, ypos),
                       inner_point(xpos + width - 1, ypos + height - 1),
                       color_by_index(color))
  end

  def set_pixel(xpos, ypos, color)
    surface.set_at(inner_point(xpos, ypos), color_by_index(color))
  end

  def rectangle(args)
    x0, y0 = args[:from]
    if args[:to]
      x1, y1 = args[:to]
    else
      x1 = x0 + (args[:w] || args[:width]) - 1
      y1 = y0 + (args[:h] || args[:height]) - 1
    end
    if args[:fill]
      fill_rect(x0, y0, x1-x0+1, y1-y0+1, args[:fill])
    else
      draw_rect(x0, y0, x1-x0+1, y1-y0+1, args[:color])
    end
  end

  def polygon(args)
    points = args[:points].map {|p| inner_point(*p) }
    if args[:fill]
      surface.draw_polygon_s(points, color_by_index(args[:fill]))
    else
      surface.draw_polygon(points, color_by_index(args[:color]))
    end
  end

  def draw_circle(xpos, ypos, radius, color)
    surface.draw_circle(inner_point(xpos + radius, ypos + radius),
                        radius,
                        color_by_index(color))
  end

  def fill_circle(xpos, ypos, radius, color)
    surface.draw_circle_s(inner_point(xpos + radius, ypos + radius),
                          radius,
                          color_by_index(color))
  end

  def circle(args)
    x, y = args[:center]
    r = args[:radius]
    x -= r
    y -= r
    if args[:fill]
      fill_circle(x, y, r, args[:fill])
    else
      draw_circle(x, y, r, args[:color])
    end
  end

  def draw_line(x0, y0, x1, y1, color)
    surface.draw_line(inner_point(x0, y0), inner_point(x1, y1),
                      color_by_index(color))
  end

  def line(args)
    x0, y0 = args[:from]
    x1, y1 = args[:to]
    draw_line(x0, y0, x1, y1, args[:color])
  end

  def plot(args)
    x, y = args[:at]
    set_pixel(x, y, args[:color])
  end

  def draw_char(char, color, xpos, ypos)
    charset.blit_char(surface, inner_point(xpos, ypos), char,
                      color_by_index(color))
  end

  def draw_border(color = border_color)
    draw_sideborder(color)
    draw_vertborder(color)
  end

  def draw_sideborder(color = border_color)
    return unless border
    surface.draw_box_s([0, 0], [border_width - 1, total_height - 1],
                       color_by_index(color))
    surface.draw_box_s([border_width + 320, 0],
                       [total_width - 1, total_height - 1],
                       color_by_index(color))
  end

  def draw_vertborder(color = border_color)
    return unless border
    surface.draw_box_s([0, 0], [total_width - 1, border_top_height - 1],
                       color_by_index(color))
    surface.draw_box_s([0, border_top_height + 200],
                       [total_width - 1, total_height - 1],
                       color_by_index(color))
  end

  def clear(include_border = true)
    if include_border
      surface.draw_box_s(outer_upper_left, outer_bottom_right,
                         color_by_index(border_color))
      surface.draw_box_s(inner_upper_left, inner_bottom_right,
                         color_by_index(screen_color))
    else
      surface.draw_box_s(outer_upper_left, outer_bottom_right,
                         color_by_index(screen_color))
    end
  end

  def inner_point(x, y)
    [x + border_width, y + border_top_height]
  end

end
