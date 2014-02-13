# Description:
#   A Hubot plugin to play sounds on http://soundspac.es.
#
# Dependencies:
#   validator: ~2.0.0
#   request: 2.30.x
#
# Configuration:
#   HUBOT_SOUNDSPACES_ROOM_KEY - This is your unique http://soundspac.es room key.
#   HUBOT_SOUNDSPACES_BASE_SOUND_URL - If you host your sound somewhere, this is the base URL for that.
#   HUBOT_SOUNDSPACES_SOUND_URL - Where your sounds are hosted. (eg. http://my.websi.te/sounds/)
#
# Commands:
#   /soundspaces - Displays the soundspac.es room you have configured.
#   /sound soundName
#   /sound http://www.dropbox.com/s/someuniquekey/hom.mp3
#   /sound https://www.dropbox.com/s/someuniquekey/hom.mp3
#
# Author:
#   jonursenbach

url = require 'url'
path = require 'path'
check = require('validator').check

request = require 'request'

module.exports = (robot) ->
  robot.hear /\/soundspaces/i, (msg) ->
    msg.send 'Listen to sounds here: http://soundspac.es'
    #if (!process.env.HUBOT_SOUNDSPACES_ROOM_KEY || process.env.HUBOT_SOUNDSPACES_ROOM_KEY == '')
    #  msg.send 'It doesn\'t appear that you\'ve set up a soundspac.es room yet. What are you waiting for?'
    #else
    #  msg.send 'Listen to sounds here: http://soundspac.es/' + process.env.HUBOT_SOUNDSPACES_ROOM_KEY

  robot.hear /\/sound (.*)/i, (msg) ->
    sound = msg.match[1].trim()
    play_sound = false

    try
      parsed_url = url.parse(sound)
      protocol = parsed_url.protocol

      # Soundspaces supports sending sound URLs that don't exist on the
      # configured base URL, but we need to make sure it's an MP3 first before
      # passing it off.
      if (protocol != null)
        ext = getSoundExtension(sound)
        if !ext
          msg.send 'I don\'t understand the name of that sound.'
          return
        else if ext != 'mp3'
          msg.send 'I can only play MP3s.'
          return
        else if (protocol.indexOf('http') == -1)
          msg.send 'I only support sounds from HTTP(s) endpoints. Sorry!'
          return

        sound_name = path.basename(sound, '.mp3')
      else
        # Check if the sound we want to play is either a poorly-formed URL (like
        # it's missing a protocol), or they're trying to send something like
        # "huuu.mp3".
        if getSoundExtension(sound)
          try
            if (check(sound).isUrl())
              msg.send 'I don\'t understand the name of that sound.'
              return
          catch error
            msg.send 'I don\'t understand the name of that sound.'
            return

          msg.send 'Don\'t specify a file extension in the sound name.'
          return

        sound_name = sound
        sound = process.env.HUBOT_SOUNDSPACES_BASE_SOUND_URL + sound + '.mp3'

      # Lets play it!
      request.post({
        uri: process.env.HUBOT_SOUNDSPACES_SOUND_URL,
        form: {
          'sound': sound_name,
          'url': sound,
          'author': msg.message.user.name
        }
      }, (error, response, body) ->
          if (error || response.statusCode != 200)
            body = JSON.parse(body)
            if (typeof body.err != 'undefined')
              msg.send 'API ERROR: ' + body.err
            else
              msg.send 'API ERROR: ' + error
      );
    catch error
      msg.send 'API ERROR: ' + error

    return

getSoundExtension = (sound) ->
  ext = path.extname(sound).split('.')
  return ext[ext.length - 1]
