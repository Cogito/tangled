define [], () ->
  class QuadTree
    constructor: (x, y, w, h) ->
      @node = new Node(this, x, y, w, h)

    add: (object) ->
      @node.add(object)

    remove: (object) ->
      @node.remove(object)

    removeChildren: ->

    getObjects: (x, y, w, h) ->
      nodes = []
      @node.getNodes([x, y, w, h], nodes)
      shapes = []
      for node in nodes
        shapes = shapes.concat(node.objects)
      return shapes

  class Node
    constructor: (@parent, @x, @y, @w, @h) ->
      @objects = []
      @children = null

    add: (object) ->
      if @objects
        @objects.push(object)

        if @objects.length > 2
          @children = [
            new Node(this, @x, @y, @w / 2, @h / 2)
            new Node(this, @x + @w / 2, @y, @w / 2, @h / 2)
            new Node(this, @x, @y + @h / 2, @w / 2, @h / 2)
            new Node(this, @x + @w / 2, @y + @h / 2, @w / 2, @h / 2)
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

    remove: (object) ->
      return if not @contains object
      if @children is null
        @objects = @objects.filter (el) -> el isnt object
        @parent.removeChildren() if @objects.length is 0
      else
        for child in @children when child.contains object
          child.remove object

    removeChildren: ->
      remove = true
      for child in @children when child.children and child.children.length isnt 0
        remove = false
      if remove
        @objects = []
        @children = null
        @parent.removeChildren()

    contains: (object) ->
      @x < object.x < @x + @w and @y < object.y < @y + @h

    overlaps: (region) ->
      @x < region[0] + region[2] and @x + @w > region[0] and @y < region[1] + region[3] and @y + @h > region[1]

    getNodes: (region, nodes) ->
      if @objects
        nodes.push this
        return
      for child in @children
        if child.overlaps(region)
          if child.objects
            nodes.push(child)
          else
            child.getNodes(region, nodes)

  return QuadTree
