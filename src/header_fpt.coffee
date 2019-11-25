fs = require 'fs'
iconv = require 'iconv-lite'

class HeaderFPT

    constructor: (@fpt_filename, @encoding) ->
        return @

    parse: (callback) ->
        fs.readFile @fpt_filename, (err, buffer) =>
            throw err if err

            @nextFreeBlock = (buffer.slice 0, 4).readInt32BE 0
            @memoSingleBlockLength = (buffer.slice 6, 8).readInt16BE 0
            callback @

module.exports = HeaderFPT