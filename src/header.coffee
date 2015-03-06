fs = require 'fs'
iconv = require 'iconv-lite'

class Header

    constructor: (@filename, @encoding) ->
        return @

    parse: (callback) ->
        fs.readFile @filename, (err, buffer) =>
            throw err if err

            @type = iconv.decode (buffer.slice 0, 1), @encoding
            @dateUpdated = @parseDate (buffer.slice 1, 4)
            @numberOfRecords = @convertBinaryToInteger (buffer.slice 4, 8)
            @start = @convertBinaryToInteger (buffer.slice 8, 10)
            @recordLength = @convertBinaryToInteger (buffer.slice 10, 12)

			# The field subrecords are each 32 bits(for dbf revs < dbase 7), the set terminated by 0x0D
            i = 32
            @fields = until buffer[i] is 0x0D
                @parseFieldSubRecord buffer.slice(i, i += 32)

            callback @

    parseDate: (buffer) =>
        year = @convertBinaryToInteger buffer.slice 0, 1
        year = if year >= 60 then year + 1900 else year + 2000
        month = (@convertBinaryToInteger buffer.slice 1, 2) - 1
        day = @convertBinaryToInteger buffer.slice 2, 3

        return new Date year, month, day

    parseFieldSubRecord: (buffer) =>
        header = {
            name: iconv.decode((buffer.slice 0, 11), @encoding).replace(/[\u0000]+$/, '')
            type: iconv.decode (buffer.slice 11, 12), @encoding
            displacement: @convertBinaryToInteger buffer.slice 12, 16
            length: @convertBinaryToInteger buffer.slice 16, 17
            decimalPlaces: @convertBinaryToInteger buffer.slice 17, 18
        }

    convertBinaryToInteger: (buffer) ->
        return buffer.readInt32LE 0, true

module.exports = Header
