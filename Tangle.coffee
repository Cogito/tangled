# Roughly, a map of nodes representing a players creation.
# The player adds nodes, which are connected to existing nodes, in order to 'grow' the tangle.
# Will need to handle connecting with existing nodes in this tangle as new nodes grow.
# Node weight will propogate along the map, redistributing itself from heavy->light nodes.
define ["utils", "Node", "QuadTree", "Graph"], (utils, Node, QuadTree, Graph) ->
  class Tangle
    constructor: (@game) ->
      @nodes = []
      #@dyingNodes = []
      @minGrowDistance = 11
      @maxGrowDistance = 12
      @maxNodeWeight = 5

      @quadtree = new QuadTree 0, 0, @game.width, @game.height
      @graph = new Graph

      @innerFillStyle = "rgba(255,255,255,1)"
      @deadzoneFillStyle = "rgb(196,51,25)"

    addNode: (node, parents...) ->
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
      node.doTransfers() for node in @nodes

    prepareTransfers: ->
      node.prepareTransfers() for node in @nodes

    findClosestNode: (point) -> utils.findClosestInSet(point, @nodes)

    findNodesNear: (point, radius = @maxGrowDistance) ->
      close = []
      quadClose = @quadtree.getObjects point.x - radius * 2, point.y - radius * 2, radius * 4, radius * 4
      for node in quadClose
        curr = utils.distanceBetween(node, point) - node.size()
        if curr < radius
          close.push(node)
      return close

    grow: (p, parent) ->
      node = new Node(this, p.x, p.y, 1)
      # Don't connect to nodes that are connected to each other, because it sucks
      closeNodes = @findNodesNear(p, @maxGrowDistance)
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

      closeNodes = closeNodes.filter (el) -> el isnt parent

      closest = utils.findClosestInSet(node, closeNodes)

      @addNode(node, closest, parent)
      node.isDying = true if not @game.inBounds(node)
      return node

    growRandomly: (n = 1, chance = 1) ->
      for node in @nodes
        # Grow like crazy!
        if node?.numConnections() == n and Math.random() <= chance and node isnt @activeNode and not node.isDying
          p = utils.offsetFrom(node, node.size() + @maxGrowDistance - 1, utils.middleAngle(node.sortedConns(), 0, Math.random() < 0.5) + Math.random() - 0.5)
          @grow(p, node)

    killNode: (node) ->
      if node.weight <= 0
        (conn.node.deleteConnection(node)) for id, conn of node.connections
        @nodes = @nodes.filter (n) -> n isnt node
      else
        node.setWeight(node.weight - 0.1)
      return

    killDyingNodes: ->
      nodesToKill = (node for node in @nodes when node?.isDying)
      for node in nodesToKill
        if node.numConnections() <= 2
           for id, conn of node.connections when conn.node.numConnections() is 2
             conn.node.isDying = true
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