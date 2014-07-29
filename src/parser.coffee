{EventEmitter} = require 'events'
Header = require './header'
HeaderFPT = require './header_fpt'
fs = require 'fs'
iconv = require 'iconv-lite'

class Parser extends EventEmitter

    constructor: (@filename, @encoding = 'utf-8', @fpt_filename) ->
        unless @fpt_filename
            base_filename = @filename.split('.dbf')[0]
            @fpt_filename = "#{base_filename}.fpt"

    parse: =>
        @emit 'start', @

        @header = new Header @filename, @encoding

        fs.exists @fpt_filename, (exists) =>
            if exists
                @header_fpt = new HeaderFPT @fpt_filename, @encoding
                @header_fpt.parse (err) =>
                @emit 'header_fpt', @header_fpt

                @fpt_buffer = fs.readFileSync @fpt_filename

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

    parseMemoRecord: (block_position) =>

        if block_position > @header_fpt.nextFreeBlock
            return ''

        block_header_start = block_position * @header_fpt.memoSingleBlockLength
        block_header_end = block_header_start + 8
        block_size = @fpt_buffer.slice(block_header_start + 4 , block_header_end ).readInt32BE 0, true

        if block_size is 0 or undefined or block_size > 2048
            return ''

        start = block_header_end
        end = start + block_size

        if end > @fpt_buffer.length
            return ''

        return (iconv.decode(@fpt_buffer.slice(start, end), @encoding)).trim()

    parseField: (field, buffer) =>

        value = (iconv.decode buffer, @encoding).trim()
        switch field.type
            when 'M'
                unless @header_fpt
                    throw new Error("Memo field was specified but related .FPT file (#{@fpt_filename}) was not found for #{@filename}.")
                block_position = buffer.readInt32LE 0, true
                if block_position is 0
                    value = ''
                else
                    value = @parseMemoRecord block_position
            when 'N' then value = parseFloat value
            when 'L'
                value = true  if value is 'T'
                value = false if value is 'F'
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