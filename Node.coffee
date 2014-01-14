define ["utils"], (utils) ->
  class Node
    constructor: (@tangle, @x, @y, @weight, connections...) ->
      @id = utils.uniqid.get()
      @setWeight(@weight)
      @connections = {}
      @transfers = []
      @addConnection(connections...)
      @connectionsCount = 0

    colour: ->
      alpha = if @isDying then @weight / @tangle.maxNodeWeight else 1
      return "rgba(255,255,255,"+alpha+")"

    transfer: (n, w) ->
      w = @weight if w > @weight
      @setWeight(@weight - w)
      n.setWeight(n.weight + w)

    size: ->
      @weight * (0.5 * @numConnections() + 1)

    setWeight: (weight) ->
      if weight < 0 then weight = 0
      @weight = if weight > @tangle.maxNodeWeight then @tangle.maxNodeWeight else weight

    prepareTransfers: ->
      self = this
      targetConnections = (conn for id, conn of @connections when conn?.node.weight < self.weight and not conn?.node.isDying)
      for conn, i in targetConnections
        @transfers[i] = {
          n: conn.node
          weight: (self.weight - conn?.node.weight) / (2 * targetConnections.length)
        }

    doTransfers: ->
      for t in @transfers
        @transfer(t.n, t.weight)
      @transfers = []

    addConnection: (nodes...) ->
      for node in nodes when node?
        @connections[node.id] = {
          node: node
          angle: Math.atan2 node.y - @y, node.x - @x
        }
        node.connections[@id] = {
          node: this
          angle: Math.atan2 @y - node.y, @x - node.x
        }
        node.connectionsCount++
        @connectionsCount++
        node.sortedConnsArray = null
        @sortedConnsArray = null

    deleteConnection: (target) ->
      if delete @connections[target.id]
        @connectionsCount--
        @sortedConnsArray = null

    numConnections: ->
      @connectionsCount #(conn for id, conn of @connections).length

    sortedConns: ->
      if not @sortedConnsArray
        @sortedConnsArray = (conn for id, conn of @connections).sort (a, b) -> a.angle - b.angle
      return @sortedConnsArray
