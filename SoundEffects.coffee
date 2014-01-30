define ["AudioBufferLoader"], (AudioBufferLoader) ->
  class SoundEffects
    constructor: (@canvas) ->
      self = this
      @sounds = {
        die: { url:"sounds/velcro-strap-2.wav" }
        grow: { url:"sounds/roll-over-1.mp3" }
      }
      @context = new AudioContext()
      @resetPosition()
      @panner = @context.createPanner()
      #@panner.coneOuterGain = 0.1
      #@panner.coneOuterAngle = 180
      #@panner.coneInnerAngle = 0
      @panner.connect @context.destination
      onload = (sounds) ->
        self.ready = true
      @audioBufferLoader = new AudioBufferLoader @context, onload

      @loadSounds()

    loadSounds: () ->
      @audioBufferLoader.load(@sounds)

    playSound: (name) ->
      source = @context.createBufferSource()
      source.buffer = @sounds[name]?.buffer
      source.connect @panner
      source.start(0)

    playSoundAt: (name, position) ->
      @changePosition(position)
      @playSound(name)
      @resetPosition()

    resetPosition: ->
      @context.listener.setPosition(0, 0, 0)

    changePosition: (position) ->
      mul = 8
      x = position.x / @canvas.width - 0.5
      y = -position.y / @canvas.height + 0.5
      #console.log "Setting position to {" + x + "," + y + ",-0.5}"
      @panner.setPosition(x * mul, y * mul, -0.5)
