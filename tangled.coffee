### This is Tangled ###


### And now other stuff ###

#QuadTree = require ["QuadTree"]
window.AudioContext = window.AudioContext || window.webkitAudioContext;
require.config({

  paths: {
    "rsvp": "bower_components/rsvp/rsvp.amd"
  }

})

Game = require ["Game"], (Game) ->
  myGame = new Game(document.getElementById('game-canvas'))
  myGame.start()
  #window.setTimeout((-> game.pause()), 3000)
  window.game = myGame

