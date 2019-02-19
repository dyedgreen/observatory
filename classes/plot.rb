require "base64"


module Plot

  class Base

    attr_accessor :color, :svg

    def initialize()
      @color = "000000"
      @svg = ""
    end

    def render
      raise NoMethodError
    end

    def base64
      "data:image/svg+xml;base64,#{Base64.encode64(@svg)}"
    end

    private

    def svg_base(body, width:100, height:100)
      <<-SVG
      <svg width="#{width}px" height="#{height}px" preserveAspectRatio="none" viewBox="0 0 #{width} #{height}" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        #{body}
      </svg>
      SVG
    end

  end # Base

  class Line < Base

    def initialize(x, y, color:"000000")
      @color = color
      render x, y
    end

    def render(x, y)
      # Points are expected to go from left
      # to right.
      raise ArgumentError unless x.count == y.count
      max_x = x.max
      max_y = y.max
      min_x = x.min
      min_y = y.min
      path = "<path d=\"M0,#{max_y - min_y} L0,#{max_y - y[0]} "
      x.zip(y).each do |pos|
        path << "#{pos[0] - min_x},#{max_y - pos[1]} "
      end
      path << "L#{max_x - min_x},#{max_y - min_y} 0,#{max_y - min_y} Z\" fill=\"\##{@color}\"></path>"
      @svg = svg_base path, width: max_x - min_x, height: max_y - min_y
      @svg
    end

  end # Line

end
