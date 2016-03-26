require "coffee-script-properties"
{EventEmitter} = require "events"

class AsyncWorkQueue extends EventEmitter

    constructor: (worker = null, @concurrency = 1) ->
        if "number" is typeof worker
            @concurrency = worker
            worker = null

        @worker = worker or @processTask

        @queue =
            head: null
            tail: null
            length: 0

        @indices = []
        @slots = []

        for i in [0 .. @concurrency - 1]
            @indices[i] = -1
            @slots.push i

    @getter "waiting", -> @queue.length
    @getter "length", -> @queue.length
    @getter "running", -> @concurrency - @slots.length
    @getter "working", -> (item for item in @indices when item isnt null)

    push: (task, callback) ->
        tasklet = 
            task: task
            callback: callback
            next: null

        if @queue.tail
            @queue.tail.next = tasklet
            @queue.tail = tasklet

        if not @queue.head
            @queue.head = @queue.tail = tasklet

        @queue.length++
        @scheduleEventLoop()

    extractTasklet: ->
        item = @queue.head

        if @queue.head is @queue.tail
            @queue.head = @queue.tail = null
        else
            @queue.head = @queue.head.next

        @queue.length--
        return item

    scheduleEventLoop: =>
        if not @eventLoopScheduled
            @eventLoopScheduled = true
            process.nextTick @eventLoop

    eventLoop: => 
        @eventLoopScheduled = false
        while (@queue.head) and ((slot = @slots.pop()) isnt undefined)
            @runTask slot, @extractTasklet()

    runTask: (slot, tasklet) ->
        @indices[slot] = tasklet.task
        try
            @worker tasklet.task, (error, data) =>
                try
                    tasklet?.callback error, data
                catch cbex
                    console.error cbex

                @indices[slot] = null
                @slots.push slot
                @scheduleEventLoop()
        catch ex
            try
                tasklet?.callback error, data
            catch cbex
                console.error cbex

            @indices[slot] = null
            @slots.push slot
            @scheduleEventLoop()

    processTask: (task, callback) ->
        callback?()


module.exports = AsyncWorkQueue