fs = require 'fs'
iconv = require 'iconv-lite'

class HeaderFPT

    constructor: (@filename, @encoding) ->
        return @

    parse: (callback) ->
        fs.readFile "#{@filename}.fpt", (err, buffer) =>
            throw err if err

            @nextFreeBlock = (buffer.slice 0, 4).readInt32BE 0, true
            @memoSingleBlockLength = (buffer.slice 6, 8).readInt16BE 0, true
            callback @

module.exports = HeaderFPT