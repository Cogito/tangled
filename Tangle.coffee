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
      @allNodesArray.push source
      @sources.push source
      @quadtree.add source
      graphNode = @graph.addNode source.id
      graphNode.node = source

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

    doTransfers: ->
      node.doTransfers() for node in @allNodes()

    prepareTransfers: ->
      node.prepareTransfers() for node in @allNodes()

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
      # Don't connect to nodes that are connected to each other, because it sucks
      closeNodes = @findNodesNear(p, @maxGrowDistance)
      closeNodes = closeNodes.concat @game.sources.filter (el) -> utils.distanceBetween(el, p) <= @maxGrowDistance
      ###found = {}
      findConnectedNodesIn = (n, set) ->
        return (conn.node for id, conn of n.connections when set.indexOf(conn.node) != -1 and not found[conn.node.id])
      findConnectedSet = (n, set) ->
        connectedNodes = findConnectedNodesIn(n, set)
        for connectedNode in connectedNodes
          found[connectedNode.id] = true
          connectedNodes = connectedNodes.concat findConnectedSet(connectedNode, set)
        return connectedNodes

      disconnectedSets = []
      set = 0
      for closeNode in closeNodes
        continue if found[closeNode.id]
        found[closeNode.id] = true
        disconnectedSets[set] = []
        disconnectedSets[set].push closeNode
        disconnectedSets[set].concat findConnectedSet(closeNode, closeNodes)
        set++
      nodesToConnectTo = []
      for disconnectedSet in disconnectedSets
        nodesToConnectTo.push utils.findClosestInSet(node, disconnectedSet)###

      closeNodes = closeNodes.filter (el) ->
        utils.vertexAngle(p, parent, el) > 3/4 * Math.PI

      closeNodes = closeNodes.sort (a, b) ->
        utils.vertexAngle(p, parent, a) - utils.vertexAngle(p, parent, b)

      closest = closeNodes[0]

      if closest instanceof Source
        @addSource closest
        @game.sources = @game.sources.filter (el) -> el isnt closest

      if closest and utils.distanceBetween(parent, closest) < @maxGrowDistance
        @addConnection(parent, closest)
        return closest
      else
        node = new Node(this, p.x, p.y, 1)
        @addNode(node, closest, parent)

        node.isDying = true if not @game.inBounds(node)

        if closest
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

    killDyingNodes: ->
      nodesToKill = (node for node in @allNodes() when node?.isDying)
      for node in nodesToKill
        if node.numConnections() <= 2
          for id, conn of node.connections when conn.node.numConnections() is 2
            conn.node.isDying = true
            @game.playSound("die", conn.node)
        @killNode node
      return

    addConnection: (node1, node2) ->
      if node1.id < node2.id
        id = node1.id +";"+ node2.id
        @connections[id] ?= new Connection(node1, node2)
      else
        id = node2.id +";"+ node1.id
        @connections[id] ?= new Connection(node2, node1)

      if not node1.connectedTo node2
        conn = new Connection(this, node1, node2)
