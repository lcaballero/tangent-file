path  = require('path')
fs    = require('fs')


module.exports =

  class TangentFile
    @defaults =
      outDirectory      : '~/tmp'
      startingNumber    : 1
      name              : 'tangent'
      number            : null
      maxFiles          : 10
      debounceDelay     : 1000      # 1 second
      filenameTemplate  : "{name}-{number}.log"

    ###
      @opts { Object } A configuration object used to guide the writing of
        the tangent file.  It's properties and definitions:
        {
          outDirectory  : # Name of the directory to write files to
          maxFiles      : # Number of files to write out before rolling
                          # over and starting the count over.
          debounceDelay : # The delay before capturing another error.
                          # This is used to keep the client from writing
                          # to disk too much.

          namePattern   :
        }
    ###
    constructor: (opts, defaults) ->
      ###
        The defaults parameter provided to this function is used by testing
        to alter the defaults that would normally be applied to this instance.

        This is usefull for overriding default behavior.  For instance, when
        trying to keep timeouts at a reasonable value (one that's not too
        small), while wanting to also test the code using those small values.

        It's mainly to keep testing times low!
      ###
      defaults = _.defaults({}, (opts or {}), TangentFile.defaults)
      opts     = _.defaults({}, (opts or {}), defaults)

      @outDirectory     = opts.outDirectory
      @maxFiles         = opts.maxFiles
      @debounceDelay    = opts.debounceDelay
      @filenameTemplate = opts.filenameTemplate
      @startingNumber   = opts.startingNumber
      @name             = opts.name
      @number           = opts.startingNumber
      @hasExecutedOnce  = false
      @lastExecutedAt   = null

    ###
      The interpolate signature take a string, some number of args, or a single
      simple js object.

      @s { String } A templated string using the '{' and '}' characters to delimit
        key names or index numbers.

      @args { Array | Object } A single js object or a list of values in array
        form, which if an object is provided then it's keys and values are
        interpolated, but if multiple values are provided then indexes are
        are interpolated.
    ###
    interpolate: (s, args...) ->
      opts =
        if args? and args.length is 1 and _.isPlainObject(args[0])
        then args[0]
        else args

      if s? and opts?
        re = /\{([^{}]*)\}/g
        s.replace(re, (a,b) ->
          r = opts[b]
          if _.isString(r) or _.isNumber(r) then r else a
        )
      else
        s or ""

    filename : (peek) ->
      @number =
        if !peek and @number >= (@startingNumber + @maxFiles)
        then @startingNumber
        else @number

      @interpolate(@filenameTemplate, {
        name    : @name
        number  : if peek then @number else (@number++)
      })

    fullname : (peek) ->
      path.resolve(@outDirectory, @filename(peek))

    write: (text, cb) ->
      now             = Date.now()
      @lastExecutedAt = if @hasExecutedOnce then now else @lastExecutedAt
      delta           = now - @lastExecutedAt > @debounceDelay

      if !@hasExecutedOnce and delta
        fs.writeFile(@fullname(), text, { encoding: 'utf8' }, (err) => cb(err, true))
        @lastExecutedAt = now
      else
        cb(null, false) # This indicates that the file wasn't immediately written.

