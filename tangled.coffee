### This is Tangled ###


### And now other stuff ###

#QuadTree = require ["QuadTree"]

Game = require ["Game"], (Game) ->
  myGame = new Game(document.getElementById('game-canvas'))
  myGame.start()
  #window.setTimeout((-> game.pause()), 3000)