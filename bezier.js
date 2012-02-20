(function() {
  var drawVectors = false;
  var clearCanvas = function (canvas, context) {
    var context = context || canvas.getContext?canvas.getContext('2d'):undefined;
    // Store the current transformation matrix
    context.save();

    // Use the identity matrix while clearing the canvas
    context.setTransform(1, 0, 0, 1, 0, 0);
    context.clearRect(0, 0, canvas.width, canvas.height);

    // Restore the transform
    context.restore();
  };

  var Point = function(x, y) {
    return {
      x: x,
      y: y,
      translate: function(vector) {
        return Point(
          this.x + vector.length * Math.cos(vector.angle),
          this.y + vector.length * Math.sin(vector.angle)
        );
      },
      vectorFrom: function(point) {
        return Vector(this.distanceTo(point), Math.atan2(this.y - point.y, this.x - point.x));
      },
      distanceTo: function (point) {
        return Math.sqrt((this.x - point.x)*(this.x - point.x) + (this.y - point.y)*(this.y - point.y));
      }
    }
  };
  var Vector = function(length, angle) {
    var rotate = function(radians) {
      return Vector(this.length, this.angle + radians); // TODO: might try to keep new angle in the range [-PI:PI] later
    };
    var scaleTo = function(len) {
      return Vector(len, this.angle);
    };
    var scale = function(percentage) {
      return Vector(this.length*percentage, this.angle);
    };
    var draw = function(context, start) {
      context.moveTo(start.x, start.y);
      context.lineTo(start.translate(this).x, start.translate(this).y);
    };
    return {
      length: length, // pixels?
      angle: angle, // radians!
      rotate: rotate,
      scaleTo: scaleTo,
      scale: scale,
      draw: draw
    };
  };
  var Node = function(v1, v2, tail) {
    var add = function(node) {
      this.tail = node;
      return node;
    };
    var extend = function(v3) {
      if (this.tail) {
        this.tail.extend(v3);
      } else {
        this.tail = Node(this.v2, v3);
      }
      return this.tail;
    };
    return {
      v1: v1,
      v2: v2,
      tail: tail, // a list of vectors! (max one to start, then two. probably no more)
      add: add,
      extend: extend
    };
  };
  var Bezier = function(startPoint, startControlVector, endPoint, endControlVector){
    var draw = function(context) {
      context.moveTo(this.start.x, this.start.y);
      context.bezierCurveTo(this.startCP.x, this.startCP.y, this.endCP.x, this.endCP.y, this.end.x, this.end.y);
    };
    var drawReverse = function(context) {
      context.moveTo(this.end.x, this.end.y);
      context.bezierCurveTo(this.endCP.x, this.endCP.y, this.startCP.x, this.startCP.y, this.start.x, this.start.y);
    };
    return {
      start: startPoint,
      startCP: startPoint.translate(startControlVector),
      end: endPoint,
      endCP: endPoint.translate(endControlVector),
      draw: draw,
      drawReverse: drawReverse
    }
  }
  var bezierPoints = function(p, v1, v2) {
    var w = 3;
    var cpInnerScale = 0.7;
    var cpOuterScale = 0.9;
    var bendLeft = (v1.angle - Math.PI < v2.angle && v2.angle < v1.angle) || (v1.angle + Math.PI < v2.angle);
    var cpLeftScale =  bendLeft ? cpInnerScale : cpOuterScale;
    var cpRightScale = bendLeft ? cpOuterScale : cpInnerScale;
    var end_point = p.translate(v1).translate(v2);
    return {
      bez1: Bezier(
        p.translate(v1.rotate(-Math.PI / 2).scaleTo(w)),
        v1.scale(cpLeftScale),
        end_point.translate(v2.rotate(-Math.PI / 2).scaleTo(w)),
        v2.rotate(Math.PI).scale(cpLeftScale)
      ),
      bez2: Bezier(
        p.translate(v1.rotate(Math.PI / 2).scaleTo(w)),
        v1.scale(cpRightScale),
        end_point.translate(v2.rotate(Math.PI / 2).scaleTo(w)),
        v2.rotate(Math.PI).scale(cpRightScale)
      )
    }
  };
  var drawPoints = function(context, start, v1, v2) {
    var curves = bezierPoints(start, v1, v2);
    context.strokeStyle = "rgb(0,0,0)";
    context.beginPath();
    curves.bez1.draw(context);
    curves.bez2.draw(context);
    context.stroke();
    if (drawVectors) {
      context.strokeStyle = "rgba(255,0,0,0.5)";
      context.beginPath();
      v1.draw(context, start);
      v2.draw(context, start.translate(v1));
      context.stroke();
    }
  };
  var draw = function(canvas, start, vectors) {
    if (canvas.getContext){
      var ctx = canvas.getContext('2d');
      clearCanvas(canvas, ctx);
      var p = start;
      var node = vectors;
      var lastPoint;
      for(; node; node = node.tail) {
        drawPoints(ctx, p, node.v1, node.v2);
        p = p.translate(node.v1).translate(node.v2);
        lastPoint = p.translate(node.v2);
      }
    }
    return lastPoint;
  };
  var start = Point(0, 50);
  var vectors = Node(Vector(20, 0), Vector(40, 1));
  vectors.extend(Vector(35,-1))
    .extend(Vector(15,0))
    .extend(Vector(25,-0.5))
    .extend(Vector(15,0.8))
    .extend(Vector(50,2.4))
    .extend(Vector(50,2.4))
    .extend(Vector(50,1.5))
    .extend(Vector(100,0));
  $(function() {
    var $canvas = $("#myCanvas");
    var endPoint = draw($canvas[0], start, vectors);
    var lastNode;
    $canvas.mousedown(function(e) {

      var parentOffset = $(this).offset();
      //or $(this).offset(); if you really just want the current element's offset
      var relX = e.pageX - parentOffset.left;
      var relY = e.pageY - parentOffset.top;

      vectors.extend(Point(relX, relY).vectorFrom(endPoint));
      draw($canvas[0], start, vectors);
      lastNode = vectors;
      while (lastNode.tail) {
        lastNode = lastNode.tail;
      }
    });
    $canvas.mousemove(function(e) {
      if (lastNode) {

      var parentOffset = $(this).offset();
      //or $(this).offset(); if you really just want the current element's offset
      var relX = e.pageX - parentOffset.left;
      var relY = e.pageY - parentOffset.top;
        lastNode.v2 = Point(relX, relY).vectorFrom(endPoint);
        draw($canvas[0], start, vectors);
        $("#angles").html((lastNode.v1.angle + (2 * Math.PI)) % (2 * Math.PI) );
      }
    });
    $canvas.mouseup(function(e) {
      endPoint = draw($canvas[0], start, vectors);
      lastNode = undefined;
    });
  });
})();
