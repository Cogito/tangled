### Some Utilities ###
define [], () ->
  # This is from some stackoverflow I forget
  uniqid = do ->
    id = 0
    { get: -> id++ }

  # Thanks Raganwald for the idea http://raganwald.com/2012/12/01/more-combinators.html
  fluent = (methodBody) ->
    return () ->
      methodBody.apply this, arguments
      return this

  requestAnimationFrame = window.requestAnimationFrame

  normaliseAngle = (angle) -> (angle + Math.PI) % (2 * Math.PI) - Math.PI

  distanceBetween = (a, b) ->  Math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
  squareDistanceBetween = (a, b) ->  (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)
  vertexAngle = (v, a, b) ->
    Math.acos(
      (squareDistanceBetween(v, a) + squareDistanceBetween(v, b) - squareDistanceBetween(a, b))/
      (2*distanceBetween(v,a)*distanceBetween(v,b))
    )


  # Creates an object with x and y defined,
  # set to the mouse position relative to the state's canvas
  # If you wanna be super-correct this can be tricky,
  # we have to worry about padding and borders
  # takes an event and a reference to the canvas
  getMouse = (e, canvas) ->
    element = canvas
    offsetX = 0
    offsetY = 0
    mx
    my

    stylePaddingLeft = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingLeft'], 10)      || 0;
    stylePaddingTop  = parseInt(document.defaultView.getComputedStyle(canvas, null)['paddingTop'], 10)       || 0;
    styleBorderLeft  = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderLeftWidth'], 10)  || 0;
    styleBorderTop   = parseInt(document.defaultView.getComputedStyle(canvas, null)['borderTopWidth'], 10)   || 0;
    # Some pages have fixed-position bars (like the stumbleupon bar) at the top or left of the page
    # They will mess up mouse coordinates and this fixes that
    html = document.body.parentNode
    htmlTop = html.offsetTop
    htmlLeft = html.offsetLeft

    # Compute the total offset. It's possible to cache this if you want
    if (element.offsetParent != undefined)
      offsetX += element.offsetLeft
      offsetY += element.offsetTop
      while element = element.offsetParent
        offsetX += element.offsetLeft
        offsetY += element.offsetTop


    # Add padding and border style widths to offset
    # Also add the <html> offsets in case there's a position:fixed bar (like the stumbleupon bar)
    # This part is not strictly necessary, it depends on your styling
    offsetX += stylePaddingLeft + styleBorderLeft + htmlLeft
    offsetY += stylePaddingTop + styleBorderTop + htmlTop

    mx = e.pageX - offsetX
    my = e.pageY - offsetY

    # We return a simple javascript object with x and y defined
    return {x: mx, y: my}

  middleAngle = (conns, index, left) ->
    nextIndex = if left then index - 1 else index + 1
    leftAngle = conns[index].angle
    if conns.length == 1
      return normaliseAngle(conns[index].angle + Math.PI)

    if left and nextIndex < 0
      rightAngle = conns[conns.length - 1].angle
    else if not left and nextIndex == conns.length
      rightAngle = conns[0].angle
    else
      rightAngle = conns[nextIndex].angle
    res = (leftAngle + rightAngle) / 2
    if (left and leftAngle < rightAngle) or ((not left) and leftAngle > rightAngle)
      res += Math.PI
    return normaliseAngle(res)

  leftOuterLineBetween = (nodeA, nodeB) ->
    startSortedConns = nodeA.sortedConns()
    endSortedConns = nodeB.sortedConns()

    node2Index = startSortedConns.indexOf nodeA.connections[nodeB.id]
    node1Index = endSortedConns.indexOf nodeB.connections[nodeA.id]

    startAngle = middleAngle(startSortedConns, node2Index, false);
    endAngle = middleAngle(endSortedConns, node1Index, true);
    return {
      start: offsetFrom(nodeA, nodeA.size(), startAngle)
      end: offsetFrom(nodeB, nodeB.size(), endAngle)
      startAngle: startAngle
      endAngle: endAngle
    }

  offsetFrom = (p, radius, angle) ->  { x: p.x + radius * Math.cos(angle), y: p.y + radius * Math.sin(angle) }

  findClosestInSet = (point, nodes) ->
    return null if nodes.length < 1
    closest = nodes[0]
    min = distanceBetween(closest, point) - closest.size()
    for node in nodes
      curr = distanceBetween(node, point) - node.size()
      if curr < min
        min = curr
        closest = node
    return closest

  return {
    uniqid
    fluent
    requestAnimationFrame
    normaliseAngle
    distanceBetween
    vertexAngle
    squareDistanceBetween
    getMouse
    middleAngle
    leftOuterLineBetween
    offsetFrom
    findClosestInSet
  }
