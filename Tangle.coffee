# Roughly, a map of nodes representing a players creation.
# The player adds nodes, which are connected to existing nodes, in order to 'grow' the tangle.
# Will need to handle connecting with existing nodes in this tangle as new nodes grow.
# Node weight will propogate along the map, redistributing itself from heavy->light nodes.
define ["utils", "Node", "Source", "QuadTree", "Graph"], (utils, Node, Source,  QuadTree, Graph) ->
  class Tangle
    constructor: (@game) ->
      @nodes = []
      @sources = []
      @allNodesArray = []
      #@dyingNodes = []
      @minGrowDistance = 11
      @maxGrowDistance = 12
      @maxNodeWeight = 5

      @quadtree = new QuadTree 0, 0, @game.width, @game.height
      @graph = new Graph

    allNodes: ->
      @allNodesArray

    addSource: (source) ->
      return if source.tangle == this
      @allNodesArray.push source
      @sources.push source
      @quadtree.add source
      graphNode = @graph.addNode source.id
      graphNode.node = source
      source.tangle = this
      return

    addNode: (node, parents...) ->
      @allNodesArray.push node
      @nodes.push node
      @quadtree.add node
      graphNode = @graph.addNode node.id
      graphNode.node = node
      node.addConnection(parents...)

    addChain: (nodes, parent) ->
      for node in nodes
        @addNode node, parent
        parent = node

    preUpdate: ->
      for node in @allNodes()
        node.prepareTransfers()
        if node.numConnections == 0
          node.isDying = true
        if node.isDying && node.numConnections() <= 2
          for id, conn of node.connections when conn.node.numConnections() <= 2
            conn.node.isDying = true
            @game.playSound("die", conn.node)
        if @findNodesNear(node).length > @game.properties.maxNeighbours
          node.isDying = true
      return

    update: ->
      for node in @allNodes()
        node.doTransfers()
        if node.isDying
          @killNode node
      return

    findClosestNode: (point) -> utils.findClosestInSet(point, @allNodes())

    findNodesNear: (point, radius = @maxGrowDistance) ->
      close = []
      quadClose = @quadtree.getObjects point.x - radius * 2, point.y - radius * 2, radius * 4, radius * 4
      for node in quadClose
        curr = utils.distanceBetween(node, point) - node.size()
        if curr < radius
          close.push(node)
      return close

    grow: (p, parent) ->
      self = this
      # Don't connect to nodes that are connected to each other, because it sucks
      closeNodes = @findNodesNear(p, @maxGrowDistance)
      closeSources = @game.sources.filter (el) -> utils.distanceBetween(el, p) <= self.maxGrowDistance
      closeNodes = closeNodes.concat closeSources

      closeNodes = closeNodes.filter (el) ->
        utils.vertexAngle(p, parent, el) > 3/4 * Math.PI

      closeNodes = closeNodes.sort (a, b) ->
        utils.vertexAngle(p, parent, a) - utils.vertexAngle(p, parent, b)

      closest = closeNodes[0]

      node = new Node(this, p.x, p.y, 1)
      @addNode(node, closest, parent)

      node.isDying = true if not @game.inBounds(node)

      if closest
        if closest instanceof Source
          @addSource closest
          @game.sources = @game.sources.filter (el) -> el isnt closest
        return closest
      else
        return node

    growRandomly: (n = 1, chance = 1) ->
      for node in @allNodes()
        # Grow like crazy!
        if node?.numConnections() == n and Math.random() <= chance and node isnt @activeNode and not node.isDying
          p = utils.offsetFrom(node, node.size() + @maxGrowDistance - 1, utils.middleAngle(node.sortedConns(), 0, Math.random() < 0.5) + Math.random() - 0.5)
          @grow(p, node)
          @game.playSound("grow_random", p)

    killNode: (node) ->
      if node.weight <= 0
        (conn.node.deleteConnection(node)) for id, conn of node.connections
        @nodes = @nodes.filter (n) -> n isnt node
        @allNodesArray = @allNodesArray.filter (n) -> n isnt node
        @quadtree.remove node
      else
        node.setWeight(node.weight - 0.1)
      return
