## Stolen from http://www.html5rocks.com/en/tutorials/webaudio/intro/js/buffer-loader.js ##
# Modified to suit Coffeescript (and my) style

define ["rsvp"], (RSVP) ->
  class AudioBufferLoader
    constructor: (@audioContext, @onload) ->

    loadBuffer: (name, sound) ->
      loader = this
      promise = new RSVP.Promise (resolve, reject) ->
        request = new XMLHttpRequest()
        handler = ->
          if (this.readyState == this.DONE)
            if (this.status == 200)
              # Asynchronously decode the audio file data in request.response
              loader.audioContext.decodeAudioData(
                request.response
                (buffer) ->
                  if (!buffer)
                    reject this
                  else
                    sound.buffer = buffer
                    resolve sound
                (error) ->
                  reject error
              )
            else
              reject(this)
        request.open("GET", sound.url, true)
        request.onreadystatechange = handler;
        request.responseType = "arraybuffer"

        request.send()

      return promise

    load: (sounds) ->
      self = this
      RSVP.all(@loadBuffer name, sound for name, sound of sounds).then((sounds) ->
        self.onload sounds
      ).catch((reason) -> console.error "Loading sounds failed.", reason)

