TangentFile = require("../src/TangentFile")
fs          = require('fs')
path        = require('path')
glob        = require('glob')
_           = require('lodash')


describe 'TangentFile =>', ->

  exists = (root, dirs...) ->
    for dir in dirs
      file = path.resolve(root, dir)
      expect(fs.existsSync(file), 'should have created file: ' + file).to.be.true

  beforeEach ->
    ###
      Setting this globally here to prevent ~/tmp (the default) from
      being written to during testing.
    ###
    TangentFile.defaults.outDirectory       = "./files/tmp"
    TangentFile.minimums.min.debounceDelay  = 1  # <= minimized for testing

  describe 'write more tangent files =>', ->

    outDir  = './files/roll'
    logs    = "#{outDir}/*.log"

    ###
      Clean up after each test so that we can properly test things like rollover.
    ###
    afterEach ->
      glob(logs, (err, res) ->
        if err?
          console.log('failed to find .log files')
        else
          for r in res
            fs.unlinkSync(r)
      )

    it 'should have written the maximum number of files', (done) ->
      overrides =
        debounceDelay : TangentFile.minimums.min.debounceDelay + 1
        outDirectory  : outDir

      t = new TangentFile(undefined, overrides)

      { startingNumber, maxFiles } = t

      count = 0
      m     = 15

      for i in [startingNumber..maxFiles]
        do ->
          setTimeout(->
            t.write("some text #{i}", (err, isWritten, fn, fqn) ->
              expect(t.number).to.be.within(startingNumber, maxFiles)
              expect(isWritten, "should have written file.").to.be.true
              count++
            )
          , i * m)

      setTimeout(->
        r = [startingNumber..maxFiles]
        for i in r
          expect(t.number).to.be.within(startingNumber, maxFiles)
          exists(t.outDirectory, t.nextFilename())

        glob(logs, (err, res) ->
          expect(err).to.not.exist
          expect(res).to.have.length(r.length)
          done()
        )
      , maxFiles * m)

  describe 'write =>', ->

    ###
      Clean up after each test so that we can properly test things like rollover.
    ###
    afterEach ->
      glob("files/tmp/*.log", (err, res) ->
        if err?
          console.log('failed to find .log files')
        else
          for r in res
            fs.unlinkSync(r)
      )

    it 'should write only once within a debounce window', (done) ->
      time        = 200
      m           = 10
      iterations  = Math.floor(time/m) + 1
      writes      = 0
      bounce      = (time / 2) - m
      t           = new TangentFile({ debounceDelay: bounce })
      count       = Math.floor((m * iterations) / t.debounceDelay) + 1

      write = (delay, iteration) -> -> t.write('some text', (err, isWritten) ->
        if isWritten then writes += 1
      )

      for i in [0..iterations]
        delay = i * m
        do ->
          setTimeout(write(delay, i), delay)

      countWrites = ->
        expect(writes).to.equal(count)
        done()

      # Setting this delay to a reasonable length beyond the last write call.
      setTimeout(countWrites, (iterations + 3) * m)

    it 'should write once the call occurs outside the debounce delay', (done) ->
      t = new TangentFile({ debounceDelay: 200 })
      t.write('some text', (err, isWritten) ->
        expect(isWritten, 'should have written first request').true
      )

      write = (delay) -> -> t.write('some text', (err, isWritten) ->
        if isWritten
          expect(delay).to.be.greaterThan(200)
          done()
      )

      m = 30
      for i in [0..(300 / m)]
        do ->
          delay = i * m
          setTimeout(write(delay), delay)


    it 'write calls occuring within the debounce delay should write only once', (done) ->
      t = new TangentFile()
      t.write('some text', (err, isWritten) ->
        expect(isWritten, 'should have written first request').true
      )

      write = -> t.write('some text', (err, isWritten) ->
        expect(isWritten, 'should not have written file within debounce window').false
      )

      i = 0; m = 10
      setTimeout(write, (++i) * m)
      setTimeout(write, (++i) * m)
      setTimeout(write, (++i) * m)
      setTimeout(write, (++i) * m)
      setTimeout(done,  (++i) * m)


    it 'on the first call it should write the text to file', (done) ->
      t = new TangentFile()
      currentFilename = t.currentFilename()

      t.write('some text', (err, isWritten, writtenFilename) ->
        exists(t.outDirectory, currentFilename)
        expect(currentFilename).to.equal(writtenFilename)
        expect(isWritten).true
        done()
      )


  describe 'filename =>', ->

    it 'should apply file name template', ->
      t = new TangentFile()
      s = t.currentFilename()
      expect(s).to.equal('tangent-1.log')

    it 'should provide the first filename', ->
      t = new TangentFile()
      vals = (t.nextFilename() for n in [t.startingNumber..t.maxFiles])
      uniq = _.unique(_.clone(vals))

      expect(vals).to.have.length(t.maxFiles)
      expect(vals).to.have.length(uniq.length)
      expect(vals).to.have.members(uniq)

    it 'should provide the first filename', ->
      t = new TangentFile()
      names = [ t.nextFilename(), t.nextFilename() ]
      expect(names[0]).to.exist
      expect(names[1]).to.exist
      expect(names[0]).to.not.equal(names[1])

  describe 'interpolate =>', ->

    it 'interpolate should handle null', ->
      t = new TangentFile()
      expect(-> t.interpolate(null)).to.not.throw(Error)

    it 'interpolate should handle undefined', ->
      t = new TangentFile()
      expect(-> t.interpolate(undefined)).to.not.throw(Error)

    it "should interpolate the { hero: 'Batman', identity: 'Bruce Wayne' }", ->
      t = new TangentFile()
      s = '{hero} is {identity}'
      opts = { hero: 'Batman', identity: 'Bruce Wayne' }
      expect(t.interpolate(s, opts)).to.equal('Batman is Bruce Wayne')

    it "should interpolate the ['Batman', 'Bruce Wayne']", ->
      t = new TangentFile()
      s = '{0} is {1}'
      expect(t.interpolate(s, 'Batman', 'Bruce Wayne')).to.equal('Batman is Bruce Wayne')

  describe 'check configuration reasonableness', ->

    it.skip 'should check for a reasonable debounceDelay', ->

    it 'should not allow zero maxFiles', ->
      expect(-> new TangentFile({ startingNumber: -1, maxFiles : 0 })).to.throw(Error)

    it 'should not allow negative maxFiles', ->
      expect(-> new TangentFile({ startingNumber: -101, maxFiles : -100 })).to.throw(Error)

    it 'should not allow a starting number above the maxFile limit', ->
      expect(-> new TangentFile({ startingNumber: 20, maxFiles : 10 })).to.throw(Error)


  describe 'contructor =>', ->

    it 'should instantiate without error', ->
      expect(-> new TangentFile()).to.not.throw(Error)

    it 'initially should not have executed', ->
      t = new TangentFile()
      expect(t.lastExecutedAt).to.not.exist

    it 'should not have a last executed time', ->
      t = new TangentFile()
      expect(t.hasYetToWrite).to.be.true

    for k,v of TangentFile.defaults
      do -> it "should default the #{k}", ->
        t = new TangentFile()
        expect(t[k], "should have #{k}").to.exist
        expect(t[k]).to.equal(v)

