{EventEmitter} = require 'events'
Header = require './header'
fs = require 'fs'
iconv = require 'iconv-lite'

class Parser extends EventEmitter

    constructor: (@filename, @encoding = 'utf-8') ->

    parse: =>
        @emit 'start', @

        @header = new Header @filename, @encoding
        @header.parse (err) =>

            @emit 'header', @header

            sequenceNumber = 0

            fs.readFile @filename, (err, buffer) =>
                throw err if err

                loc = @header.start
                while loc < (@header.start + @header.numberOfRecords * @header.recordLength) and loc < buffer.length
                    @emit 'record', @parseRecord ++sequenceNumber, buffer.slice loc, loc += @header.recordLength

                @emit 'end', @

        return @

    parseRecord: (sequenceNumber, buffer) =>
        record = {
            '@sequenceNumber': sequenceNumber
            '@deleted': (buffer.slice 0, 1)[0] isnt 32
        }

        loc = 1
        for field in @header.fields
            do (field) =>
                record[field.name] = @parseField field, buffer.slice loc, loc += field.length

        return record

    parseField: (field, buffer) =>
        value = (iconv.decode buffer, @encoding).trim()

        switch field.type

            when 'N' then value = parseFloat value
            when 'L' then value = value is 1
            when 'D'
                if value
                    year = parseInt(value.slice 0,4)
                    month = parseInt(value.slice 4,6)-1
                    day = parseInt(value.slice 6,8)
                    value = new Date year, month , day
                else
                    value = ''
            else
                value

        return value

module.exports = Parser