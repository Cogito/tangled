define [], () ->
  class Rectangle
    constructor: (@x1, @y1, @x2, @y2) ->

    width: -> @x2 - @x1
    height: -> @y2 - @y1

    translate: (p) ->
      @x1 += p.x
      @x2 += p.x
      @y1 += p.y
      @y2 += p.y
      return this

    # Scales around center of Rectangle
    scaleCenter: (s) ->
      # add/remove half the scaled amount from each side of the rectangle
      width = @width()
      height = @height()
      @x1 -= width * (s - 1) / 2
      @x2 += width * (s - 1) / 2
      @y1 -= height * (s - 1) / 2
      @y2 += height * (s - 1) / 2
      return this

    scaleAroundPoint: (p, s) ->
      @x1 = s * (@x1 - p.x) + p.x
      @y1 = s * (@y1 - p.y) + p.y
      @x2 = s * (@x2 - p.x) + p.x
      @y2 = s * (@y2 - p.y) + p.y
      return this
