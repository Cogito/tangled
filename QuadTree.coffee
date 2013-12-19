define [], () ->
  class QuadTree
    constructor: (x, y, w, h) ->
      @node = new Node(x, y, w, h)

    add: (object) ->
      @node.add(object)

    getObjects: (x, y, w, h) ->
      nodes = []
      @node.getNodes([x, y, w, h], nodes)
      shapes = []
      for node in nodes
        shapes = shapes.concat(node.objects)
      return shapes

  class Node
    constructor: (@x, @y, @w, @h) ->
      @objects = []
      @children = null

    add: (object) ->
      if @objects
        @objects.push(object)

        if @objects.length > 2
          @children = [
            new Node(@x, @y, @w / 2, @h / 2)
            new Node(@x + @w / 2, @y, @w / 2, @h / 2)
            new Node(@x, @y + @h / 2, @w / 2, @h / 2)
            new Node(@x + @w / 2, @y + @h / 2, @w / 2, @h / 2)
          ]

          for object in @objects
            for node in @children
              if node.contains(object)
                node.add(object)
                break

          @objects = null
      else
        for node in @children
          if node.contains(object)
            node.add(object)

    contains: (object) ->
      @x < object.x < @x + @w and @y < object.y < @y + @h

    overlaps: (region) ->
      @x < region[0] + region[2] and @x + @w > region[0] and @y < region[1] + region[3] and @y + @h > region[1]

    getNodes: (region, nodes) ->
      for child in @children
        if child.overlaps(region)
          if child.objects
            nodes.push(child)
          else
            child.getNodes(region, nodes)

  return QuadTree