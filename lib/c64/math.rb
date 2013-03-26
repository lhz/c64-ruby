
module C64
  module Math
    include ::Math

    TAU = 2 * PI

    def ucos(ua)
      cos(ua * TAU)
    end

    def usin(ua)
      sin(ua * TAU)
    end

  end
end
