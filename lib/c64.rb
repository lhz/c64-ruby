require 'c64/version'
require 'c64/color'
require 'c64/image'
require 'c64/math'
require 'c64/util'
require 'c64/helpers'
require 'matrix'

module C64
end


class Point
  attr_accessor :x, :y
  def self.[](x, y)
    new(x, y)
  end
  def initialize(x, y)
    @x = x
    @y = y
  end
  def inspect
    "(#{@x},#{@y})"
  end
  def eql?(other)
    @x == other.x && @y == other.y
  end
  def hash
    [@x, @y].hash
  end
end


class Rectangle
  attr_accessor :upper_left, :lower_right
  def self.[](ul, lr)
    new(ul, lr)
  end
  def initialize(ul, lr)
    @upper_left  = ul
    @lower_right = lr
  end
  def xmin
    upper_left.x
  end
  def ymin
    upper_left.y
  end
  def xmax
    lower_right.x
  end
  def ymax
    lower_right.y
  end
  def width
    xmax - xmin + 1
  end
  def height
    ymax - ymin + 1
  end
end


class Matrix
  def []=(i, j, value)
    @rows[i][j] = value
  end
end
