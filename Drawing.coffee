define ["utils"], (utils) ->
  class Drawing
    constructor: (@game) ->
      @tangle = @game.tangle
      @canvas = @game.canvas
      @ctx = @canvas.getContext('2d')
      @frameWidth = @canvas.width
      @frameHeight = @canvas.height

    clear: ->
      @ctx.save()
      @ctx.fillStyle = @tangle.deadzoneFillStyle
      @ctx.fillRect(0, 0, @frameWidth, @frameHeight)
      @ctx.fillStyle = "rgb(0,0,0)"
      @ctx.fillRect(@game.border, @game.border, @frameWidth - 2 * @game.border, @frameHeight - 2 * @game.border)
      @ctx.restore()

    drawTangle: (tangle) ->
      @ctx.strokeStyle = "rgba(255,0,255,0.15)"
      @ctx.fillStyle = tangle.innerFillStyle
      @ctx.beginPath()
      for node in tangle.nodes
        @drawNode(node)
      @ctx.fill()
      @ctx.stroke()

    drawConnection: (node1, node2) ->
      if (!node1 or !node2 or node1 is node2 or node2.weight > node1.weight)
        return
      deviationAngle = 0.5
      deviationRadius = 1
      leftLine = utils.leftOuterLineBetween(node1, node2)
      leftCP1 = utils.offsetFrom(node1, node1.weight + deviationRadius, leftLine.startAngle - deviationAngle)
      leftCP2 = utils.offsetFrom(node2, node2.weight + deviationRadius, leftLine.endAngle + deviationAngle)
      rightLine = utils.leftOuterLineBetween(node2, node1)
      rightCP1 = utils.offsetFrom(node2, node2.weight + deviationRadius, rightLine.startAngle - deviationAngle)
      rightCP2 = utils.offsetFrom(node1, node1.weight + deviationRadius, rightLine.endAngle + deviationAngle)

      #@ctx.fillStyle = node2.colour()
      #@ctx.beginPath()
      # line between nodes
      #@ctx.moveTo(node1.x, node1.y);
      #@ctx.lineTo(node2.x, node2.y);
      #@ctx.stroke()
      # body of tangle segment
      @ctx.moveTo(leftLine.start.x, leftLine.start.y)
      @ctx.bezierCurveTo(leftCP1.x, leftCP1.y, leftCP2.x, leftCP2.y, leftLine.end.x, leftLine.end.y)
      @ctx.lineTo(rightLine.start.x, rightLine.start.y)
      @ctx.bezierCurveTo(rightCP1.x, rightCP1.y, rightCP2.x, rightCP2.y, rightLine.end.x, rightLine.end.y)
      @ctx.lineTo(leftLine.start.x, leftLine.start.y)
      #@ctx.stroke()
      #@ctx.fill()
      #@ctx.closePath()

    drawNode: (node) ->
      radius = node.weight
      if node.numConnections() < 1
        #@ctx.fillStyle = if node.active then "rgba(255,0,255,0.5)" else "rgba(255,255,255,0.5)"
        @ctx.moveTo(node.x,node.y)
        @ctx.arc(node.x, node.y, radius, 0 , 2 * Math.PI)
      else
        #@ctx.fillStyle = node.colour()
        sortedConns = node.sortedConns()
        startp = utils.offsetFrom(node, node.weight, utils.middleAngle(sortedConns, sortedConns.length - 1, true))
        @ctx.moveTo(startp.x, startp.y)
        for c, i in sortedConns
          p = utils.offsetFrom(node, node.weight, utils.middleAngle(sortedConns, i, true))
          @ctx.lineTo(p.x, p.y)
        @ctx.lineTo(startp.x, startp.y)
      @drawConnection(node, conn?.node) for id, conn of node.connections

